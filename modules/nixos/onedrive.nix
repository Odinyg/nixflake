
{ lib, config, pkgs, ... }:
{
  options = {
    onedrive = {
      enable = lib.mkEnableOption {
        description = "Enable onedrive";
        default = false;
      };
    };
  };
  config = lib.mkIf config.onedrive.enable {
    environment.systemPackages = with pkgs; [
    onedrive
    onedrivegui
    ];
    };
}
