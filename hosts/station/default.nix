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

  nixpkgs.config.permittedInsecurePackages = [
    "electron-36.9.5"
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

  # Static IP on Servers VLAN (10.10.10.0/24, VLAN 5)
  networking.interfaces.enp82s0.ipv4.addresses = [
    {
      address = "10.10.10.10";
      prefixLength = 24;
    }
  ];
  networking.defaultGateway = {
    address = "10.10.10.1";
    interface = "enp82s0";
  };
  networking.nameservers = [
    "10.10.10.1"
    "1.1.1.1"
  ];

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
      "dialout"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEb3q553HODR8Yipt69tmLrGOqLTfde/G8yntaitNkA3"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINezFWDmtlGHBF674DcsNi+wDMrSp13pNX1lo4RcJTMm"
    ];
  };

  # ==============================================================================
  # SECURITY - SOPS
  # ==============================================================================
  # Note: Station uses direct sops configuration instead of the secrets module
  # because it has different requirements (different user, no SSH key management)
  sops.defaultSopsFile = ./../../secrets/general.yaml;
  sops.age.keyFile = "/home/${config.user}/.config/sops/age/keys.txt";

  # ==============================================================================
  # HARDWARE - NVIDIA GPU
  # ==============================================================================
  hardware.nvidia-gpu = {
    enable = true;
    driverPackage = "latest"; # Use latest drivers for better OpenGL support
    open = false; # Use proprietary drivers for better gaming stability
    prime.enable = false; # Desktop GPU, no hybrid graphics
  };

  environment.variables.__GL_VRR_ALLOWED = "0";

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
  services.logind = {
    lidSwitch = "ignore";
    lidSwitchDocked = "ignore";
    lidSwitchExternalPower = "ignore";
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
  # Remote tmux sessions
  tmux.sessions = [
    {
      name = "vnpc-21";
      startup_command = "ssh odin@vnpc-21 -t tmux new-session -A -s main";
    }
    {
      name = "laptop";
      startup_command = "ssh none@laptop -t tmux new-session -A -s main";
    }
  ];

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

      decoration.blur.enabled = lib.mkForce false;
      misc.vrr = lib.mkForce 0;
      render.direct_scanout = lib.mkForce 0;

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

      windowrule = lib.mkAfter [
        # Keep Battle.net / WoW on the HDMI gaming workspace and avoid
        # workspace-switch compositor effects that can freeze Proton windows.
        "match:title ^(.*(Battle\\.net|World of Warcraft|WoW Classic).*)$, workspace 1 silent"
        "match:title ^(.*Battle\\.net.*)$, float on"
        "match:title ^(.*(Battle\\.net|World of Warcraft|WoW Classic).*)$, idle_inhibit always"
        "match:title ^(.*(World of Warcraft|WoW Classic).*)$, border_size 0"
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
  lmstudio.enable = true;
  mcp.enable = true;

  # ProtonVPN
  services.resolved.enable = true;

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

  environment.systemPackages = [
    pkgs.protonvpn-gui
    pkgs.woeusb-ng
    pkgs.ntfs3g
  ];

  # Local dev database
  networking.extraHosts = "127.0.0.1 postgres.local";
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_17;
  };

  hosted-services.open-webui.enable = true;
  # ==============================================================================
  # SYSTEM VERSION
  # ==============================================================================
  system.stateVersion = "25.05";
}
