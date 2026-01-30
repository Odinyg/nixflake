{ lib, config, ... }:
{
  options = {
    tailscale = {
      enable = lib.mkEnableOption "tailscale";
    };
  };
  config = lib.mkIf config.tailscale.enable {
    services.tailscale = {
      enable = true;
      openFirewall = true;
    };
    networking.firewall.trustedInterfaces = [ "tailscale0" ];
  };
}
