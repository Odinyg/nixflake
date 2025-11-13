{
  lib,
  config,
  pkgs,
  ...
}:
{
  options = {
    bluetooth = {
      enable = lib.mkEnableOption "bluetooth";
    };
  };
  config = lib.mkIf config.bluetooth.enable {
    services.libinput.enable = true;

    #  sound.enable = true;
    hardware = {
      bluetooth.enable = true; # enables support for Bluetooth
      bluetooth.powerOnBoot = true;
      bluetooth.input.General.UserspaceHID = true;
    };
    services.blueman.enable = true;
    environment.systemPackages = with pkgs; [
      libinput
    ];

  };
}
