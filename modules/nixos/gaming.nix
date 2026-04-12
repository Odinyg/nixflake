{
  lib,
  config,
  pkgs,
  pkgs-unstable,
  ...
}:
let
  cfg = config.gaming;
in
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

  config = lib.mkIf cfg.enable {
    programs.steam = lib.mkIf cfg.steam.enable {
      enable = true;
      remotePlay.openFirewall = cfg.steam.remotePlay;
      dedicatedServer.openFirewall = cfg.steam.dedicatedServer;
      gamescopeSession.enable = cfg.performance.gamescope;
    };

    programs.gamemode = lib.mkIf cfg.performance.gamemode {
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

    programs.gamescope = lib.mkIf cfg.performance.gamescope {
      enable = true;
      capSysNice = true;
    };

    environment.systemPackages = lib.flatten [
      (lib.optionals cfg.launchers.lutris [ pkgs-unstable.lutris ])
      (lib.optionals cfg.launchers.heroic [ pkgs-unstable.heroic ])
      (lib.optionals cfg.launchers.bottles [ pkgs-unstable.bottles ])
      (lib.optionals cfg.emulation.enable (
        with pkgs-unstable;
        [
          retroarch
          pcsx2
          dolphin-emu
          mupen64plus
        ]
      ))

      pkgs-unstable.wineWow64Packages.stable
      pkgs-unstable.winetricks
      pkgs-unstable.protontricks

      pkgs.vulkan-tools # vulkaninfo for diagnostics

      pkgs.antimicrox # Controller mapping

      pkgs.pulseeffects-legacy
    ];

    hardware.graphics.enable32Bit = true;

    boot.kernelModules = [ "uinput" ];

    users.users.${config.user}.extraGroups = [ "gamemode" ];

    security.rtkit.enable = true;

    # Enable nix-ld for dynamically linked binaries (umu-run/pressure-vessel)
    programs.nix-ld.enable = true;
  };
}
