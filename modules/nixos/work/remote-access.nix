{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.work.remoteAccess;
in
{
  options = {
    work.remoteAccess = {
      enable = lib.mkEnableOption "remote access tools (Remmina, OpenVPN)";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      openvpn
    ];
  };
}
