{
  lib,
  config,
  ...
}:
{
  options.netbird-client.enable = lib.mkEnableOption "Netbird VPN client";

  config = lib.mkIf config.netbird-client.enable {
    services.netbird.enable = true;

    # Trust the Netbird interface
    networking.firewall.trustedInterfaces = [ "wt0" ];
  };
}
