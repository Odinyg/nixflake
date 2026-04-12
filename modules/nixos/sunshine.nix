{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.sunshine;
in
{

  options = {
    sunshine = {
      enable = lib.mkEnableOption "sunshine";
    };
  };
  config = lib.mkIf cfg.enable {
    networking.extraHosts = "127.0.0.1 sunshine.local";
    services.avahi.publish.enable = true;
    services.avahi.publish.userServices = true;
    services.sunshine = {
      enable = true;
      autoStart = true;
      openFirewall = true;
      capSysAdmin = true;
      settings = {
        sunshine_name = config.networking.hostName;
        origin_web_ui_allowed = "wan";
        resolutions = "[\n  1920x1080,\n  2560x1440,\n  3840x2160\n]";
      };
    };
  };
}
