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

  # Lock keybinding, display-off timeout, and native Hyprland monitor config.
  # Native rules auto-activate on hotplug; the wildcard line catches any
  # unknown external display that gets plugged in.
  home-manager.users.${config.user} = {
    wayland.windowManager.hyprland.settings = {
      bind = [
        "SUPER SHIFT, L, exec, loginctl lock-session"
      ];

      monitor = [
        "eDP-1, 1920x1200, 0x0, 1"
        ", preferred, auto, 1"
      ];
    };

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
