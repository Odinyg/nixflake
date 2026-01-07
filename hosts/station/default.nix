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
    ../../profiles/desktop.nix
  ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # ==============================================================================
  # BOOT CONFIGURATION
  # ==============================================================================
  boot.loader.grub = {
    enable = true;
    device = "/dev/nvme0n1";
    useOSProber = true;
  };

  # ==============================================================================
  # NETWORKING
  # ==============================================================================
  networking.hostName = "station";

  # ==============================================================================
  # USERS
  # ==============================================================================
  users.users.none = {
    shell = pkgs.zsh;
    isNormalUser = true;
    description = "none";
    extraGroups = [ "networkmanager" "wheel" "plugdev" ];
  };

  # ==============================================================================
  # SECURITY - SOPS
  # ==============================================================================
  # Note: Station uses direct sops configuration instead of the secrets module
  # because it has different requirements (different user, no SSH key management)
  sops.defaultSopsFile = ./../../secrets/general.yaml;
  sops.defaultSopsFormat = "yaml";
  sops.age.keyFile = /home/none/.config/sops/age/keys.txt;

  # ==============================================================================
  # HARDWARE - NVIDIA GPU
  # ==============================================================================
  nvidia-gpu.enable = true;

  # ==============================================================================
  # POWER MANAGEMENT - DISABLE SLEEP/SUSPEND
  # ==============================================================================
  # Prevent system from sleeping or suspending
  systemd.sleep.extraConfig = ''
    AllowSuspend=no
    AllowHibernation=no
    AllowSuspendThenHibernate=no
    AllowHybridSleep=no
  '';

  # Disable lid switch actions (if applicable)
  services.logind.settings = {
    Login = {
      HandleLidSwitch = "ignore";
      HandleLidSwitchDocked = "ignore";
      HandleLidSwitchExternalPower = "ignore";
    };
  };

  # Disable NVIDIA suspend/resume services (not needed for desktop that never sleeps)
  systemd.services.nvidia-suspend.enable = false;
  systemd.services.nvidia-hibernate.enable = false;
  systemd.services.nvidia-resume.enable = false;

  # ==============================================================================
  # DISTRIBUTED BUILDS - BUILD SERVER
  # ==============================================================================
  distributedBuilds = {
    enable = true;
    isBuilder = true;
  };

  # ==============================================================================
  # HOST-SPECIFIC OVERRIDES
  # ==============================================================================
  # Gaming
  gaming = {
    enable = true;
    launchers = {
      heroic = true;
      bottles = true;
    };
  };

  # Encryption tools
  crypt.enable = true;

  # Terminal opacity
  styling.opacity.terminal = 0.85;

  # Disable lockscreen/idle management (causes crashes on HDMI disconnect)
  home-manager.users.none = {
    programs.swaylock.enable = lib.mkForce false;
    services.hypridle.enable = lib.mkForce false;

    wayland.windowManager.hyprland.settings = {
      # Default gaps (for DP-1 monitor)
      general = {
        gaps_in = lib.mkForce 0;
        gaps_out = lib.mkForce 0;
      };

      # Assign workspaces to monitors
      workspace = [
        "1, monitor:HDMI-A-1, default:true"
        "2, monitor:HDMI-A-1"
        "3, monitor:HDMI-A-1"
        "4, monitor:HDMI-A-1"
        "5, monitor:HDMI-A-1"
        "6, monitor:DP-1, default:true"
        "7, monitor:DP-1"
        "8, monitor:DP-1"
        "9, monitor:DP-1"
        "10, monitor:DP-1"
      ];
    };

    # Use extraConfig for workspace gap rules
    wayland.windowManager.hyprland.extraConfig = ''
      # Large gaps for HDMI monitor workspaces (1-5)
      workspace = 1, gapsin:0, gapsout:0 100 200 100
      workspace = 2, gapsin:0, gapsout:0 100 200 100
      workspace = 3, gapsin:0, gapsout:0 100 200 100
      workspace = 4, gapsin:0, gapsout:0 100 200 100
      workspace = 5, gapsin:0, gapsout:0 100 200 100
    '';
  };

  # AI / LLM Tools
  ollama.enable = true;
  alpaca.enable = true;
  oterm.enable = true;

  # VPN
  protonvpn.enable = true;

  # Monitor Configuration
  hyprland.kanshi.profiles = [
    {
      profile.name = "station-dual";
      profile.outputs = [
        {
          criteria = "DP-1";
          mode = "1920x1080@120";
          position = "0,0";
        }
        {
          criteria = "HDMI-A-1";
          mode = "3840x2160@60";
          position = "1920,0";
        }
      ];
    }
  ];

  # Monitor configuration
  hyprland.monitors.extraConfig = ''
    monitor = HDMI-A-1, 3840x2160@60, 1920x0, 1
    monitor = DP-1, 1920x1080@120, 0x0, 1
  '';

  # ==============================================================================
  # SYSTEM PACKAGES
  # ==============================================================================
  environment.systemPackages = with pkgs; [
    inputs.zen-browser.packages."${pkgs.stdenv.hostPlatform.system}".default
  ];

  hosted-services.n8n.enable = true;
  # ==============================================================================
  # SYSTEM VERSION
  # ==============================================================================
  system.stateVersion = "25.05";
}

