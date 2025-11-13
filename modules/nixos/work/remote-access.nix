{
  pkgs,
  config,
  lib,
  ...
}:
{
  options = {
    work.remoteAccess = {
      enable = lib.mkEnableOption "remote access tools (Remmina, OpenVPN)";
    };
  };

  config = lib.mkIf config.work.remoteAccess.enable {
    environment.systemPackages = with pkgs; [
      remmina
      openvpn
    ];
  };
}