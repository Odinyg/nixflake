{ config, pkgs, lib, inputs, ... }: {
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
    unmanaged = [ ];
    ensureProfiles.profiles.modem = {
      connection = {
        id = "modem";
        type = "802-3-ethernet";
        interface-name = "enp0s31f6";
        autoconnect = "true";
        autoconnect-priority = "-1";
      };
      "802-3-ethernet" = {
        mac-address = "98:FA:9B:B7:3A:A3";
      };
      ipv4 = {
        method = "auto";
        addresses = "192.168.1.99/24,192.168.2.99/24,192.168.250.99/24";
        never-default = "true";
        ignore-auto-routes = "true";
        ignore-auto-dns = "true";
      };
      ipv6 = {
        method = "disabled";
        never-default = "true";
      };
    };
  };

  # Disable wait-online to speed up boot
  systemd.network.wait-online.enable = false;

  # Don't block boot waiting for USB NIC — configure it only when plugged in
  systemd.services."network-addresses-enp45s0u2u3".wantedBy = lib.mkForce [ ];
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="enp45s0u2u3", TAG+="systemd", ENV{SYSTEMD_WANTS}+="network-addresses-enp45s0u2u3.service"
  '';

  # ==============================================================================
  # USERS
  # ==============================================================================
  users.extraGroups.vboxusers.members = [ "odin" ];
  users.users.odin = {
    shell = pkgs.zsh;
    isNormalUser = true;
    description = "odin";
    extraGroups =
      [ "lp" "scanner" "docker" "networkmanager" "wheel" "plugdev" ];
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
  hyprland = {
    enable = true;

    # Kanshi display profiles for dynamic monitor configuration
    kanshi.profiles = [
      # External triple monitor setup
      {
        profile.name = "external-monitors";
        profile.outputs = [
          {
            criteria = "eDP-1";
            position = "0,0";
            scale = 1.25;
          }
          {
            criteria = "DP-4";
            mode = "2560x1440";
            position = "1536,0";
          }
          {
            criteria = "DP-5";
            mode = "2560x1440";
            position = "4096,0";
          }
        ];
      }
      # Laptop screen only
      {
        profile.name = "vnpc-21-only";
        profile.outputs = [{
          criteria = "eDP-1";
          status = "enable";
          mode = "1920x1080";
          scale = 1.0;
        }];
      }
    ];

    # Hyprland workspace assignments
    monitors.extraConfig = ''
      # VNPC-21: Triple monitor workspace setup
      workspace = 1, monitor:DP-4, default:true
      workspace = 2, monitor:DP-4
      workspace = 3, monitor:DP-4
      workspace = 4, monitor:DP-4
      workspace = 5, monitor:DP-4

      workspace = 6, monitor:DP-5, default:true
      workspace = 7, monitor:DP-5
      workspace = 8, monitor:DP-5

      workspace = 9, monitor:HDMI-A-1
      workspace = 0, monitor:HDMI-A-1
    '';
  };

  # COSMIC desktop environment
  cosmic.enable = true;
  cosmic.autoLogin.enable = false;

  programs.kdeconnect.enable = true;
  localsend.enable = true;

  # Secrets management
  secrets.enable = true;

  # Work tools
  onedrive.enable = false;

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
  # SYSTEM VERSION
  # ==============================================================================
  system.stateVersion = "25.05";
}
