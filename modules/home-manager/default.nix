{ config, lib, ... }:
{
  imports = [
    ./app
    ./cli
    ./misc
    ./desktop
  ];
  options = {
    user = lib.mkOption {
      type = lib.types.str;
      description = "Primary user of the system";
    };
    # Declared here (NixOS-only chain) so standalone HM uses HM's own xdg.enable without conflict.
    xdg = {
      enable = lib.mkEnableOption "XDG base directory specification";
    };
  };
}
