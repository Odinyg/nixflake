{
  config,
  lib,
  ...
}:
let
  cfg = config.server.ntfy;
in
{
  options.server.ntfy = {
    enable = lib.mkEnableOption "ntfy push notification service";
    port = lib.mkOption {
      type = lib.types.port;
      default = 2586;
      description = "Port for the ntfy web interface and API";
    };
    domain = lib.mkOption {
      type = lib.types.str;
      default = "pytt.io";
      description = "Base domain for ntfy";
    };
  };

  config = lib.mkIf cfg.enable {
    services.ntfy-sh = {
      enable = true;
      settings = {
        listen-http = ":${toString cfg.port}";
        base-url = "https://ntfy.${cfg.domain}";
        behind-proxy = true;
        auth-default-access = "deny-all";
      };
    };

    systemd.services.ntfy-sh = {
      partOf = [ "homelab.target" ];
      wantedBy = [ "homelab.target" ];
    };

    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
