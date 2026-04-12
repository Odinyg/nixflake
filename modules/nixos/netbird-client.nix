{
  lib,
  config,
  pkgs-unstable,
  ...
}:
let
  cfg = config.netbird-client;
in
{
  options = {
    netbird-client = {
      enable = lib.mkEnableOption "Netbird VPN client";
    };
  };

  config = lib.mkIf cfg.enable {
    services.netbird.enable = true;
    services.netbird.package = pkgs-unstable.netbird;

    # systemd-resolved for proper split DNS (Netbird registers via D-Bus)
    services.resolved.enable = true;

    # Trust the Netbird interface
    networking.firewall.trustedInterfaces = [ "wt0" ];
  };
}
