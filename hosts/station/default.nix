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
    ../../profiles/hardware/nvidia.nix
  ];

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
    extraGroups = [
      "networkmanager"
      "wheel"
      "plugdev"
    ];
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
  hardware.nvidia-gpu.enable = true;

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

  # AI / LLM Tools
  ollama.enable = true;
  alpaca.enable = true;
  oterm.enable = true;

  # ==============================================================================
  # SYSTEM PACKAGES
  # ==============================================================================
  environment.systemPackages = with pkgs; [
    inputs.zen-browser.packages."${pkgs.stdenv.hostPlatform.system}".default
  ];

  # ==============================================================================
  # SYSTEM VERSION
  # ==============================================================================
  system.stateVersion = "25.05";
}