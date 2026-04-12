{
  lib,
  config,
  pkgs-unstable,
  ...
}:
let
  cfg = config.tailscale;
in
{
  options = {
    tailscale = {
      enable = lib.mkEnableOption "tailscale";
    };
  };
  config = lib.mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      package = pkgs-unstable.tailscale;
      extraSetFlags = [ "--accept-routes" ];
    };
    networking.firewall.trustedInterfaces = [ "tailscale0" ];
  };
}
