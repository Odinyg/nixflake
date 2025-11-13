{ config, lib, ... }:
{

  options = {
    gammastep = {
      enable = lib.mkEnableOption "Gammastep screen temperature adjustment";
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
          brightness = 1.0;
          brightness-day = 1.0;
          brightness-night = 0.85;
          gamma = 0.9;
          gamma-day = 0.95;
          gamma-night = 0.9;
          adjustment-method = "randr";
        };
        randr = {
          screen = 0;
        };
      };
    };
  };
}
