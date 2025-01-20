{
  lib,
  pkgs,
  config,
  ...
}:
{

  options = {
    sunshine = {
      enable = lib.mkEnableOption {
        description = "Enable several sunshine";
        default = false;
      };
    };
  };
  config = lib.mkIf config.sunshine.enable {
    services.avahi.publish.enable = true;
    services.avahi.publish.userServices = true;
    services.sunshine = {
      enable = true;
      autoStart = true;
      openFirewall = true;
      capSysAdmin = true;
    };
  };
}
