{
  lib,
  config,
  pkgs,
  ...
}:
{
  options = {
    audio = {
      enable = lib.mkEnableOption {
        description = "Enable audio";
        default = false;
      };
    };
  };
  config = lib.mkIf config.audio.enable {

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;

      extraConfig.pipewire = {
        "10-clock-rates" = {
          "context.properties" = {
            "default.clock.rate" = 44100; # Set to match most of your music
            "default.clock.allowed-rates" = [
              44100
              48000
              88200
              96000
              192000
            ];
            "default.clock.quantum" = 256;
            "default.clock.min-quantum" = 32;
            "default.clock.max-quantum" = 8192;
          };
        };
      };

      extraConfig.pipewire-pulse = {
        "92-high-quality" = {
          "context.modules" = [
            {
              name = "libpipewire-module-protocol-pulse";
              args = {
                "pulse.min.quantum" = "256/48000";
                "server.address" = [ "unix:native" ];
              };
            }
          ];
          "stream.properties" = {
            "resample.quality" = 15; # Maximum quality resampling
          };
        };
      };
    };
    environment.systemPackages = with pkgs; [ pavucontrol ];

  };
}
