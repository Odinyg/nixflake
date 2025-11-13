{
  config,
  pkgs,
  lib,
  ...
}:
{

  options = {
    randr = {
      enable = lib.mkEnableOption "randr";
    };
  };
  config = lib.mkIf config.randr.enable {
    environment.systemPackages = [
      pkgs.xorg.xrandr
      pkgs.arandr
    ];
    services = {
      autorandr = {
        enable = true;

      };
    };

  };
}
