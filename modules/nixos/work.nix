{
  pkgs,
  config,
  lib,
  inputs,
  ...
}:
let
  # Create stable packages overlay
  pkgs-stable = import inputs.nixpkgs-stable {
    system = pkgs.system;
    config.allowUnfree = true;
  };
in
{

  options = {
    work = {
      enable = lib.mkEnableOption {
        description = "Enable several work";
        default = false;
      };
    };
  };
  config = lib.mkIf config.work.enable {

    environment.systemPackages = with pkgs; [
      expect
      anydesk
      pkgs-stable.dbeaver-bin
      flameshot
      rpiboot
      gnumake
      insync
      gcc
      kuro
      openvpn
      zoom-us
      remmina
      inetutils
    ];
  };
}
