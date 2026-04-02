{
  lib,
  config,
  pkgs-unstable,
  ...
}:
{
  options.netbird-client.enable = lib.mkEnableOption "Netbird VPN client";

  config = lib.mkIf config.netbird-client.enable {
    services.netbird.package = pkgs-unstable.netbird;
    services.netbird.clients.wt0.port = 51820;

    # Routing features (replaces removed useRoutingFeatures = "client")
    boot.kernel.sysctl."net.ipv4.conf.all.rp_filter" = lib.mkForce 2; # loose reverse path filtering

    # systemd-resolved for proper split DNS (Netbird registers via D-Bus)
    services.resolved.enable = true;

    # Trust the Netbird interface
    networking.firewall.trustedInterfaces = [ "wt0" ];
  };
}
