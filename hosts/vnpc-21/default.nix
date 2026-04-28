{
  config,
  pkgs,
  pkgs-unstable,
  lib,
  inputs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../profiles/workstation.nix
    ../../profiles/hardware/nvidia.nix
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
  networking.hostName = "VNPC-21";
  networking.networkmanager = {
    enable = true;
    unmanaged = [ "enp0s31f6" ];
  };

  # Built-in ethernet: static IPs for device config (no DHCP, won't affect WiFi)
  # Higher metric (200) so USB NIC (enp45s0u2u3) is preferred when both are connected
  networking.interfaces.enp0s31f6 = {
    useDHCP = false;
    ipv4.addresses = [
      {
        address = "192.168.1.99";
        prefixLength = 24;
      }
      {
        address = "192.168.2.99";
        prefixLength = 24;
      }
      {
        address = "192.168.105.99";
        prefixLength = 24;
      }
      {
        address = "192.168.250.99";
        prefixLength = 24;
      }
    ];
    ipv4.routes = [
      {
        address = "192.168.1.0";
        prefixLength = 24;
        options.metric = "200";
      }
      {
        address = "192.168.2.0";
        prefixLength = 24;
        options.metric = "200";
      }
      {
        address = "192.168.105.0";
        prefixLength = 24;
        options.metric = "200";
      }
      {
        address = "192.168.250.0";
        prefixLength = 24;
        options.metric = "200";
      }
    ];
  };

  # Disable wait-online to speed up boot
  systemd.network.wait-online.enable = false;

  # Start USB NIC config when device appears, don't block boot if absent
  systemd.services."network-addresses-enp45s0u2u3".wantedBy = lib.mkForce [
    "sys-subsystem-net-devices-enp45s0u2u3.device"
  ];

  # ==============================================================================
  # USERS
  # ==============================================================================
  users.extraGroups.vboxusers.members = [ "odin" ];
  users.users.odin = {
    shell = pkgs.zsh;
    isNormalUser = true;
    description = "odin";
    extraGroups = [
      "lp"
      "scanner"
      "docker"
      "networkmanager"
      "wheel"
      "plugdev"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEb3q553HODR8Yipt69tmLrGOqLTfde/G8yntaitNkA3"
    ];
    packages = with pkgs; [
      rclone
      tree
      libva-utils
      mesa-demos
      vulkan-tools
      wayland-utils
      kdePackages.kate
      screen
      shutter
      pkgs-unstable.rpi-imager
    ];
  };

  # ==============================================================================
  # HARDWARE - NVIDIA GPU
  # ==============================================================================
  hardware.nvidia-gpu.enable = true;

  # ==============================================================================
  # HOST-SPECIFIC OVERRIDES
  # ==============================================================================
  # Desktop environments
  hyprland.enable = true;

  # Turn screens off 15 minutes after lock
  home-manager.users.odin.services.hypridle.settings.listener = lib.mkAfter [
    {
      timeout = 1500;
      on-timeout = "hyprctl dispatch dpms off";
      on-resume = "hyprctl dispatch dpms on";
    }
  ];

  # NVIDIA workarounds + native Hyprland monitor config. Rules only activate
  # when the named output is connected, so docking/undocking is transparent.
  # eDP-1 at 0,0 (1920 wide); DP-4 at 1920,0; DP-5 at 4480,0. Wildcard catches
  # any unknown external plugged in later.
  home-manager.users.odin.wayland.windowManager.hyprland.settings = {
    cursor = {
      no_hardware_cursors = true;
      no_break_fs_vrr = true;
    };
    opengl = {
      nvidia_anti_flicker = true;
    };

    monitor = [
      "eDP-1, 1920x1080, 0x0, 1"
      "DP-4, 2560x1440, 1920x0, 1"
      "DP-5, 2560x1440, 4480x0, 1"
      "HDMI-A-1, preferred, auto-right, 1"
      ", preferred, auto, 1"
    ];

    workspace = [
      "1, monitor:DP-4, default:true"
      "2, monitor:DP-4"
      "3, monitor:DP-4"
      "4, monitor:DP-4"
      "5, monitor:DP-4"
      "6, monitor:DP-5, default:true"
      "7, monitor:DP-5"
      "8, monitor:DP-5"
      "9, monitor:HDMI-A-1"
      "0, monitor:HDMI-A-1"
    ];
  };

  # NVIDIA-specific browser environment variables
  home-manager.users.odin.home.sessionVariables = {
    MOZ_DISABLE_RDD_SANDBOX = "1";
    MOZ_X11_EGL = "1";
  };

  programs.kdeconnect.enable = true;
  programs.localsend = {
    enable = true;
    openFirewall = true;
  };

  # Secrets management
  secrets.enable = true;

  # Terminal multiplexer
  tmux.enable = true;
  tmux.sessions = [
    {
      name = "station";
      startup_command = "ssh none@station -t tmux new-session -A -s main";
    }
    {
      name = "laptop";
      startup_command = "ssh none@laptop -t tmux new-session -A -s main";
    }
  ];

  # Network sharing
  init-net.enable = true;

  # ==============================================================================
  # DISTRIBUTED BUILDS - USE STATION AS BUILDER
  # ==============================================================================
  distributedBuilds = {
    enable = true;
    isBuilder = false;
    cachePublicKey = "station:IH2kzUkYwmAVyk7J1XIgfIMw4d2vb5xA8ID8Ns9m7Xc=";
  };

  # ==============================================================================
  # SERVICES
  # ==============================================================================
  # Printing drivers
  services.printing.drivers = with pkgs; [
    brgenml1lpr
    brgenml1cupswrapper
    ptouch-driver
    gutenprint
    cups-filters
    ghostscript
  ];

  # SSH configuration
  programs.ssh = {
    startAgent = true;
    extraConfig = ''
      AddKeysToAgent yes
    '';
  };

  # Disable GNOME GCR SSH agent — conflicts with programs.ssh.startAgent above.
  # google-chrome enables it transitively; we use ssh-agent directly instead.
  services.gnome.gcr-ssh-agent.enable = false;

  # ==============================================================================
  # SYSTEM PACKAGES
  # ==============================================================================
  environment.systemPackages = with pkgs; [
    pciutils
    system-config-printer
    lshw
    tailscale
  ];

  # ==============================================================================
  # GIT GLOBAL IGNORES
  # ==============================================================================
  home-manager.users.odin.programs.git.ignores = [
    ".opencode/"
    ".claude/"
    "SCRATCHPADS/"
    "AGENTS.md"
    "CLAUDE.md"
    "opencode.json"
    "tmpclaude-*"
    "scratchpads/"
    "workflow/"
    ".agents/"
  ];

  # ==============================================================================
  # WINDOWS VM (dockur/windows, KVM-accelerated, web viewer on :8006)
  # ==============================================================================
  # Disabled for now — flip enable back to true and uncomment the desktop entry
  # below to bring the VM back up.
  hosted-services.windows-vm = {
    enable = false;
    version = "11"; # Windows 11 Pro
  };

  # Webapp for the Windows VM web viewer — local to this host since the
  # container binds to localhost.
  # home-manager.users.odin.xdg.desktopEntries.webapp-windows = {
  #   name = "Windows";
  #   exec = ''launch-or-focus chrome-127.0.0.1 "chromium --app=http://127.0.0.1:8006"'';
  #   icon = "chromium";
  #   type = "Application";
  #   terminal = false;
  #   categories = [
  #     "Network"
  #     "System"
  #   ];
  # };

  # ==============================================================================
  # SYSTEM VERSION
  # ==============================================================================
  system.stateVersion = "25.11";
}
