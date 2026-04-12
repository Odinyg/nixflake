{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.audio;
in
{
  options = {
    audio = {
      enable = lib.mkEnableOption "audio";
    };
  };
  config = lib.mkIf cfg.enable {
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    environment.systemPackages = with pkgs; [ pavucontrol ];
  };
}
