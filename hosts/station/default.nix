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
    inputs.brain.nixosModules.flush-client
  ];

  nixpkgs.config.permittedInsecurePackages = [
    "electron-36.9.5"
    "olm-3.2.16"
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
  sops.defaultSopsFile = ./../../secrets/secrets.yaml;
  sops.age.keyFile = "/home/${config.user}/.config/sops/age/keys.txt";

  # ==============================================================================
  # HARDWARE - AMD GPU
  # ==============================================================================
  amd-gpu.enable = true;

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
        "1, monitor:HDMI-A-2, default:true"
        "2, monitor:HDMI-A-2"
        "3, monitor:HDMI-A-2"
        "4, monitor:HDMI-A-2"
        "5, monitor:HDMI-A-2"
        "6, monitor:DP-2, default:true"
        "7, monitor:DP-2"
        "8, monitor:DP-2"
        "9, monitor:DP-2"
        "10, monitor:DP-2"
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

  };

  # AI / LLM Tools
  ollama.enable = false;
  lmstudio.enable = false;
  mcp.enable = true;

  # ProtonVPN
  services.resolved.enable = true;

  # Monitor Configuration
  hyprland.kanshi.profiles = [
    {
      profile.name = "station-dual";
      profile.outputs = [
        {
          criteria = "DP-2";
          mode = "2560x1440@59.95";
          position = "0,0";
          transform = "270";
        }
        {
          criteria = "HDMI-A-2";
          mode = "3840x2160@60";
          position = "1440,200";
        }
      ];
    }
  ];

  # Monitor configuration
  hyprland.monitors.extraConfig = ''
    monitor = DP-2, 2560x1440@59.95, 0x0, 1, transform, 3
    monitor = HDMI-A-2, 3840x2160@60, 1440x200, 1
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

  hosted-services.open-webui.enable = false;

  # Second Brain — flush client (POSTs session summaries to nero)
  server.brain-flush-client = {
    enable = true;
    user = "none";
    enableBootstrap = true;
    urlPrimary = "http://nero.netbird.pytt.io:8765/flush";
    urlFallback = "http://10.10.30.115:8765/flush";
  };

  # Source the rendered env file in interactive shells so Claude Code's
  # SessionEnd hook inherits BRAIN_FLUSH_* + FLUSH_TOKEN
  environment.interactiveShellInit = ''
    [ -r ${config.server.brain-flush-client.envFilePath} ] && \
      set -a && . ${config.server.brain-flush-client.envFilePath} && set +a
  '';

  # ==============================================================================
  # SYSTEM VERSION
  # ==============================================================================
  system.stateVersion = "25.05";
}
