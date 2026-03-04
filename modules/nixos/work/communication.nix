{ pkgs, config, lib, ... }:
{
  options = {
    work.communication = {
      enable = lib.mkEnableOption "work communication tools (Zoom, AnyDesk)";
    };
  };

  config = lib.mkIf config.work.communication.enable {
    environment.systemPackages = with pkgs; [
      anydesk
      teams-for-linux
      zoom-us
    ];
  };
}
