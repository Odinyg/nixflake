{ config, lib, pkgs, ... }:
{

  options = {
    zen-browser = {
      enable = lib.mkEnableOption "Zen browser";
    };
  };

  config.home-manager.users.${config.user} = lib.mkIf config.zen-browser.enable {

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

    # XDG desktop integration
    xdg.desktopEntries.zen-browser = {
      name = "Zen Browser";
      genericName = "Web Browser";
      exec = "zen %U";
      terminal = false;
      categories = [ "Application" "Network" "WebBrowser" ];
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
}
