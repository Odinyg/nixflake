{ config, lib, ... }: {

  options = {
    gammastep = {
      enable = lib.mkEnableOption {
        description = "Enable several gammastep";
        default = false;
      }; 
    };
  };
  config.home-manager.users.${config.user} = lib.mkIf config.gammastep.enable {

services.gammastep = {
  enable = true;
  provider = "manual";
  latitude = 61.9;
  longitude = 6.5;
  settings = {

    general = {
      brightness=0.9;
      brightness-day=0.9;
      brightness-night=0.7;
      gamma=0.8;
      gamma-day=0.8;
      gamma-night=0.9;
      adjustment-method = "randr";
    };
    randr = {
      screen = 0;
  };
};
  };
  };
}
