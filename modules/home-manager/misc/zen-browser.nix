{
  config,
  lib,
  options,
  pkgs,
  inputs,
  ...
}:
let
  # options.environment only exists in NixOS, not standalone Home Manager
  standalone = !(options ? environment);

  hmConfig = {
    # Wayland and NVIDIA environment variables for Zen browser
    home.sessionVariables = {
      # Enable Wayland support
      MOZ_ENABLE_WAYLAND = "1";
      MOZ_WAYLAND_USE_VAAPI = "1";

      # NVIDIA-specific settings
      MOZ_DISABLE_RDD_SANDBOX = "1";
      MOZ_X11_EGL = "1";

      # Hardware acceleration
      MOZ_USE_XINPUT2 = "1";
    };

    # FirefoxPWA native messaging host
    home.packages = [ pkgs.firefoxpwa ];
    home.file.".mozilla/native-messaging-hosts/firefoxpwa.json".source =
      "${pkgs.firefoxpwa}/lib/mozilla/native-messaging-hosts/firefoxpwa.json";

    # XDG desktop integration
    xdg.desktopEntries.zen-browser = {
      name = "Zen Browser";
      genericName = "Web Browser";
      exec = "zen-beta %U";
      terminal = false;
      categories = [
        "Application"
        "Network"
        "WebBrowser"
      ];
      mimeType = [
        "text/html"
        "text/xml"
        "application/xhtml+xml"
        "application/xml"
        "application/vnd.mozilla.xul+xml"
        "application/rss+xml"
        "application/rdf+xml"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
      ];
    };
  };
in
{

  options = {
    zen-browser = {
      enable = lib.mkEnableOption "Zen browser";
    };
  };

  config = lib.mkMerge (
    [
      {
        home-manager.users.${config.user} = lib.mkIf config.zen-browser.enable hmConfig;
      }
    ]
    ++ lib.optionals (!standalone) [
      (lib.mkIf config.zen-browser.enable {
        # Install zen-browser as a system package (from flake input)
        environment.systemPackages = [
          inputs.zen-browser.packages."${pkgs.stdenv.hostPlatform.system}".default
        ];
      })
    ]
    ++ lib.optionals standalone [
      (lib.mkIf config.zen-browser.enable hmConfig)
    ]
  );
}
