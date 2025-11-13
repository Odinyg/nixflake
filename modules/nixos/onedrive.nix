{
  lib,
  config,
  pkgs,
  ...
}:
{
  options = {
    onedrive = {
      enable = lib.mkEnableOption "onedrive";
    };
  };
  config = lib.mkIf config.onedrive.enable {

    services.onedrive.enable = true;
    environment.systemPackages = with pkgs; [
      onedrive
      onedrivegui
    ];
  };
}
