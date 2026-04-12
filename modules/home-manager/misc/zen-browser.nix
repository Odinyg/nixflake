{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.zen-browser;
in
{

  options = {
    zen-browser = {
      enable = lib.mkEnableOption "Zen browser";
    };
  };

  config = lib.mkIf cfg.enable {
    # Install zen-browser as a system package (from flake input)
    environment.systemPackages = [
      inputs.zen-browser.packages."${pkgs.stdenv.hostPlatform.system}".default
    ];

    home-manager.users.${config.user} = {
      # Wayland and hardware acceleration environment variables for Zen browser
      home.sessionVariables = {
        MOZ_ENABLE_WAYLAND = "1";
        MOZ_WAYLAND_USE_VAAPI = "1";
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
  };
}
