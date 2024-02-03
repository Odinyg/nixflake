{ config, pkgs, lib, ... }: {

  options = {
    randr = {
      enable = lib.mkEnableOption {
        description = "Enable randr.";
        default = false;
      }; 
    };
  };
    config = lib.mkIf  config.wireless.enable{
      environment.systemPackages = [ pkgs.xorg.xrandr ];
      services = {
        autorandr = { 
          enable = true;

        };
      };

  };
}
