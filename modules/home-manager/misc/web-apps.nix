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
        exec = ''launch-or-focus chrome-github "chromium --app=https://github.com"'';
        icon = "chromium";
        type = "Application";
        terminal = false;
        categories = [
          "Network"
          "WebBrowser"
        ];
      };
      webapp-youtube = {
        name = "YouTube";
        exec = ''launch-or-focus chrome-youtube "chromium --app=https://youtube.com"'';
        icon = "chromium";
        type = "Application";
        terminal = false;
        categories = [
          "Network"
          "WebBrowser"
        ];
      };
      webapp-claude = {
        name = "Claude";
        exec = ''launch-or-focus chrome-claude "chromium --app=https://claude.ai"'';
        icon = "chromium";
        type = "Application";
        terminal = false;
        categories = [
          "Network"
          "WebBrowser"
        ];
      };
      webapp-protonmail = {
        name = "ProtonMail";
        exec = ''launch-or-focus chrome-protonmail "chromium --app=https://mail.proton.me"'';
        icon = "chromium";
        type = "Application";
        terminal = false;
        categories = [
          "Network"
          "WebBrowser"
        ];
      };
      webapp-homeassistant = {
        name = "Home Assistant";
        exec = ''launch-or-focus chrome-homeassistant "chromium --app=https://homeassistant.pytt.io"'';
        icon = "chromium";
        type = "Application";
        terminal = false;
        categories = [
          "Network"
          "WebBrowser"
        ];
      };
      webapp-tradingview = {
        name = "TradingView";
        exec = ''launch-or-focus chrome-tradingview "chromium --app=https://tradingview.com/chart/EWLeEGVs/"'';
        icon = "chromium";
        type = "Application";
        terminal = false;
        categories = [
          "Network"
          "WebBrowser"
        ];
      };
      webapp-element = {
        name = "Element";
        exec = ''launch-or-focus chrome-element "chromium --app=https://element.pytt.io"'';
        icon = "chromium";
        type = "Application";
        terminal = false;
        categories = [
          "Network"
          "WebBrowser"
        ];
      };
      webapp-outlook = {
        name = "Outlook";
        exec = ''launch-or-focus chrome-outlook "chromium --app=https://outlook.office.com"'';
        icon = "chromium";
        type = "Application";
        terminal = false;
        categories = [
          "Network"
          "Email"
        ];
      };
      webapp-teams = {
        name = "Teams";
        exec = ''launch-or-focus chrome-teams "chromium --app=https://teams.cloud.microsoft/"'';
        icon = "chromium";
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
      #     exec = ''launch-or-focus chrome-DOMAIN "chromium --app=https://DOMAIN"'';
      #     icon = "chromium";
      #     type = "Application";
      #     terminal = false;
      #     categories = [ "Network" "WebBrowser" ];
      #   };
    };
  };
}
