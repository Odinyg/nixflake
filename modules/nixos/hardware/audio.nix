{
  lib,
  config,
  pkgs,
  ...
}:
{
  options = {
    audio = {
      enable = lib.mkEnableOption "audio";
    };
  };
  config = lib.mkIf config.audio.enable {
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    environment.systemPackages = with pkgs; [ pavucontrol ];
  };
}
