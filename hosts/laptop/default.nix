{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../profiles/laptop.nix
  ];

  # ==============================================================================
  # BOOT CONFIGURATION
  # ==============================================================================
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  # ==============================================================================
  # NETWORKING
  # ==============================================================================
  networking.hostName = "laptop";

  # ==============================================================================
  # USERS
  # ==============================================================================
  users.users.none = {
    shell = pkgs.zsh;
    isNormalUser = true;
    description = "none";
    extraGroups = [
      "networkmanager"
      "plugdev"
      "wheel"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEb3q553HODR8Yipt69tmLrGOqLTfde/G8yntaitNkA3"
    ];
  };

  # ==============================================================================
  # HOST-SPECIFIC OVERRIDES
  # ==============================================================================
  # Remote tmux sessions
  tmux.sessions = [
    {
      name = "vnpc-21";
      startup_command = "ssh odin@vnpc-21 -t tmux new-session -A -s main";
    }
    {
      name = "station";
      startup_command = "ssh none@station -t tmux new-session -A -s main";
    }
  ];

  secrets.enable = true;

  gaming.enable = true;
  fail2ban-security.enable = false;

  # ProtonVPN
  environment.systemPackages = [ pkgs.protonvpn-gui ];
  services.resolved.enable = true;

  # Hyprland display configuration
  hyprland = {
    kanshi.profiles = [
      {
        profile.name = "laptop-only";
        profile.outputs = [
          {
            criteria = "eDP-1";
            status = "enable";
            mode = "1920x1200";
            scale = 1.0;
          }
        ];
      }
    ];
  };

  # Lock keybinding and display-off timeout (laptop only)
  home-manager.users.${config.user} = {
    wayland.windowManager.hyprland.settings.bind = [
      "SUPER SHIFT, L, exec, loginctl lock-session"
    ];

    services.hypridle.settings.listener = [
      {
        timeout = 3600;
        on-timeout = "hyprctl dispatch dpms off";
        on-resume = "hyprctl dispatch dpms on";
      }
    ];
  };
  # ==============================================================================
  # DISTRIBUTED BUILDS - USE STATION AS BUILDER
  # ==============================================================================
  distributedBuilds = {
    enable = true;
    isBuilder = false;
    cachePublicKey = "station:IH2kzUkYwmAVyk7J1XIgfIMw4d2vb5xA8ID8Ns9m7Xc=";
  };

  # Cursor customization
  styling.cursor.package = pkgs.bibata-cursors;
  styling.cursor.name = "Bibata-Modern-Ice";

  # ==============================================================================
  # SYSTEM VERSION
  # ==============================================================================
  system.stateVersion = "25.05";
}
