{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.web-apps;
  launchOrFocusScript = pkgs.writeShellScriptBin "launch-or-focus" (
    builtins.readFile ./scripts/launch-or-focus.sh
  );
in
{
  options.web-apps = {
    enable = lib.mkEnableOption "Web app launchers";
  };

  config.home-manager.users.${config.user} = lib.mkIf cfg.enable {
    home.packages = [ launchOrFocusScript ];

    xdg.desktopEntries = {
      webapp-github = {
        name = "GitHub";
        exec = ''launch-or-focus brave-github "brave --app=https://github.com"'';
        icon = "brave-browser";
        type = "Application";
        terminal = false;
        categories = [
          "Network"
          "WebBrowser"
        ];
      };
      webapp-youtube = {
        name = "YouTube";
        exec = ''launch-or-focus brave-youtube "brave --app=https://youtube.com"'';
        icon = "brave-browser";
        type = "Application";
        terminal = false;
        categories = [
          "Network"
          "WebBrowser"
        ];
      };
      webapp-ytmusic = {
        name = "YouTube Music";
        exec = ''launch-or-focus brave-music.youtube.com "brave --app=https://music.youtube.com"'';
        icon = "brave-browser";
        type = "Application";
        terminal = false;
        categories = [
          "Network"
          "Audio"
        ];
      };
      webapp-claude = {
        name = "Claude";
        exec = ''launch-or-focus brave-claude "brave --app=https://claude.ai"'';
        icon = "brave-browser";
        type = "Application";
        terminal = false;
        categories = [
          "Network"
          "WebBrowser"
        ];
      };
      webapp-protonmail = {
        name = "ProtonMail";
        exec = ''launch-or-focus brave-protonmail "brave --app=https://mail.proton.me"'';
        icon = "brave-browser";
        type = "Application";
        terminal = false;
        categories = [
          "Network"
          "WebBrowser"
        ];
      };
      webapp-homeassistant = {
        name = "Home Assistant";
        exec = ''launch-or-focus brave-homeassistant "brave --app=https://homeassistant.pytt.io"'';
        icon = "brave-browser";
        type = "Application";
        terminal = false;
        categories = [
          "Network"
          "WebBrowser"
        ];
      };
      webapp-tradingview = {
        name = "TradingView";
        exec = ''launch-or-focus brave-tradingview "brave --app=https://tradingview.com/chart/EWLeEGVs/"'';
        icon = "brave-browser";
        type = "Application";
        terminal = false;
        categories = [
          "Network"
          "WebBrowser"
        ];
      };
      webapp-element = {
        name = "Element";
        exec = ''launch-or-focus brave-element "brave --app=https://element.pytt.io"'';
        icon = "brave-browser";
        type = "Application";
        terminal = false;
        categories = [
          "Network"
          "WebBrowser"
        ];
      };
      webapp-outlook = {
        name = "Outlook";
        exec = ''launch-or-focus brave-outlook "brave --app=https://outlook.office.com"'';
        icon = "brave-browser";
        type = "Application";
        terminal = false;
        categories = [
          "Network"
          "Email"
        ];
      };
      webapp-teams = {
        name = "Teams";
        exec = ''launch-or-focus brave-teams "brave --app=https://teams.cloud.microsoft/"'';
        icon = "brave-browser";
        type = "Application";
        terminal = false;
        categories = [
          "Network"
          "Chat"
        ];
      };

      # --- TEMPLATE: Add new web apps ---
      # Copy a webapp-NAME block above and customize:
      #   webapp-NAME = {
      #     name = "Display Name";
      #     exec = ''launch-or-focus brave-DOMAIN "brave --app=https://DOMAIN"'';
      #     icon = "brave-browser";
      #     type = "Application";
      #     terminal = false;
      #     categories = [ "Network" "WebBrowser" ];
      #   };
    };
  };
}
