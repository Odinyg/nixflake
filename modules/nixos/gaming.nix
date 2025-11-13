{
  lib,
  config,
  pkgs,
  ...
}:
{
  options = {
    gaming = {
      enable = lib.mkEnableOption "gaming optimizations and software";

      steam = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable Steam gaming platform";
        };

        remotePlay = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable Steam Remote Play";
        };

        dedicatedServer = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable Steam Dedicated Server support";
        };
      };

      performance = {
        gamemode = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable GameMode for automatic performance optimizations";
        };

        gamescope = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable Gamescope Wayland compositor for gaming";
        };
      };

      emulation = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable game emulation software";
        };
      };

      launchers = {
        lutris = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable Lutris game launcher";
        };

        heroic = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable Heroic Games Launcher (Epic/GOG)";
        };

        bottles = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable Bottles (Wine manager)";
        };
      };
    };
  };

  config = lib.mkIf config.gaming.enable {
    programs.steam = lib.mkIf config.gaming.steam.enable {
      enable = true;
      remotePlay.openFirewall = config.gaming.steam.remotePlay;
      dedicatedServer.openFirewall = config.gaming.steam.dedicatedServer;
      gamescopeSession.enable = config.gaming.performance.gamescope;
    };

    programs.gamemode = lib.mkIf config.gaming.performance.gamemode {
      enable = true;
      enableRenice = true;
      settings = {
        general = {
          renice = 10;
          ioprio = 7;
          inhibit_screensaver = 1;
        };
        gpu = {
          apply_gpu_optimisations = "accept-responsibility";
          gpu_device = 0;
        };
      };
    };

    programs.gamescope = lib.mkIf config.gaming.performance.gamescope {
      enable = true;
      capSysNice = true;
    };

    environment.systemPackages =
      with pkgs;
      lib.flatten [
        (lib.optionals config.gaming.launchers.lutris [ lutris ])
        (lib.optionals config.gaming.launchers.heroic [ heroic ])
        (lib.optionals config.gaming.launchers.bottles [ bottles ])
        (lib.optionals config.gaming.emulation.enable [
          retroarch
          pcsx2
          dolphin-emu
          mupen64plus
        ])

        wineWowPackages.stable
        winetricks
        protontricks

        antimicrox # Controller mapping

        pavucontrol
        pulseeffects-legacy
      ];

    hardware.graphics.enable32Bit = true;

    boot.kernelModules = [ "uinput" ];

    users.users.${config.user}.extraGroups = [ "gamemode" ];

    security.rtkit.enable = true;
  };
}
