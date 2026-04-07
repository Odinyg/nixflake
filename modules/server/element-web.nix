{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.server.element-web;
in
{
  options.server.element-web = {
    enable = lib.mkEnableOption "Element Web Matrix client (static, served by Caddy)";

    homeserverUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://matrix.pytt.io";
      description = "Base URL of the Matrix homeserver Element should connect to.";
    };

    serverName = lib.mkOption {
      type = lib.types.str;
      default = "pytt.io";
      description = "Matrix server_name (the part after @user:).";
    };

    package = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      description = "Element Web package with config.json baked in. Reference from Caddy via `config.server.element-web.package`.";
    };
  };

  config = lib.mkIf cfg.enable {
    server.element-web.package = pkgs.element-web.override {
      conf = {
        default_server_config = {
          "m.homeserver" = {
            base_url = cfg.homeserverUrl;
            server_name = cfg.serverName;
          };
        };
        brand = "Element";
        disable_custom_urls = false;
        disable_guests = true;
        disable_3pid_login = true;
        default_country_code = "NO";
        show_labs_settings = true;
        room_directory.servers = [ cfg.serverName ];
      };
    };
  };
}
