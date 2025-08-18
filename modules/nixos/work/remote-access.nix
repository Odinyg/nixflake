{
  pkgs,
  config,
  lib,
  ...
}:
{
  options = {
    work.remoteAccess = {
      enable = lib.mkEnableOption {
        description = "Enable remote access tools (Remmina, OpenVPN)";
        default = false;
      };
    };
  };

  config = lib.mkIf config.work.remoteAccess.enable {
    environment.systemPackages = with pkgs; [
      remmina
      openvpn
    ];
  };
}