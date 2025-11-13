{
  lib,
  pkgs,
  config,
  ...
}:
{

  options = {
    sunshine = {
      enable = lib.mkEnableOption "sunshine";
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
