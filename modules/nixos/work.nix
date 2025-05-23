{
  pkgs,
  config,
  lib,
  ...
}:
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
      teams-for-linux
      anydesk
      dbeaver-bin
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
