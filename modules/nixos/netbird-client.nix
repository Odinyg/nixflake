{
  lib,
  config,
  pkgs-unstable,
  ...
}:
{
  options.netbird-client.enable = lib.mkEnableOption "Netbird VPN client";

  config = lib.mkIf config.netbird-client.enable {
    services.netbird.enable = true;
    services.netbird.package = pkgs-unstable.netbird;
    services.netbird.useRoutingFeatures = "client";

    # systemd-resolved for proper split DNS (Netbird registers via D-Bus)
    services.resolved.enable = true;

    # Trust the Netbird interface
    networking.firewall.trustedInterfaces = [ "wt0" ];
  };
}
