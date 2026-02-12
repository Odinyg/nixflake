{ lib, config, pkgs-unstable, ... }:
{
  options = {
    tailscale = {
      enable = lib.mkEnableOption "tailscale";
    };
  };
  config = lib.mkIf config.tailscale.enable {
    services.tailscale = {
      enable = true;
      package = pkgs-unstable.tailscale;
    };
  };
}
