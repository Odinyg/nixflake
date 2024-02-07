{ lib, config, pkgs ,... }: {
  options = {
    audio = {
      enable = lib.mkEnableOption {
        description = "Enable audio";
        default = false;
      }; 
    };
  };
config = lib.mkIf  config.audio.enable{

  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  environment.systemPackages = with pkgs; [
      pavucontrol
    ];



};
}
