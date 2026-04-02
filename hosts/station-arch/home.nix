{ pkgs, lib, ... }:
{
  # Keep the same top-level option names that the NixOS-integrated HM modules expect.
  user = "none";
  hyprland.enable = true;
  git.enable = true;
  mcp.enable = true;

  neovim.enable = true;

  zsh.enable = true;
  prompt.enable = true;
  kitty.enable = true;
  ghostty.enable = true;
  tmux.enable = true;
  system-tools.enable = true;
  direnv.enable = true;
  languages.enable = true;
  kubernetes.enable = true;
  xdg.enable = true;
  zellij.enable = true;

  discord.enable = true;
  development.enable = true;
  media.enable = true;
  communication.enable = true;
  utilities.enable = true;
  lmstudio.enable = true;
  chromium.enable = true;
  zen-browser.enable = true;
  thunar.enable = true;

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

  # Disable lockscreen/idle management (causes crashes on HDMI disconnect)
  programs.swaylock.enable = lib.mkForce false;
  services.hypridle.enable = lib.mkForce false;

  # Hyprland host-specific behavior
  wayland.windowManager.hyprland.package = null;
  wayland.windowManager.hyprland.settings = {
    general = {
      gaps_in = lib.mkForce 0;
      gaps_out = lib.mkForce 0;
    };

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

  wayland.windowManager.hyprland.extraConfig = ''
    # Large gaps for HDMI monitor workspaces (1-5)
    workspace = 1, gapsin:0, gapsout:0 100 200 100
    workspace = 2, gapsin:0, gapsout:0 100 200 100
    workspace = 3, gapsin:0, gapsout:0 100 200 100
    workspace = 4, gapsin:0, gapsout:0 100 200 100
    workspace = 5, gapsin:0, gapsout:0 100 200 100
  '';

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

  hyprland.monitors.extraConfig = ''
    monitor = HDMI-A-1, 3840x2160@60, 1920x0, 1
    monitor = DP-1, 1920x1080@120, 0x0, 1
  '';

  # Stylix theming — Nord theme, dark polarity
  stylix.enable = true;
  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/nord.yaml";
  stylix.image = ../../modules/home-manager/desktop/hyprland/wallpaper/wallpaper.png;
  stylix.polarity = "dark";
  stylix.opacity.terminal = 0.85;
  stylix.autoEnable = true;
  stylix.cursor.package = pkgs.bibata-cursors;
  stylix.cursor.name = "Bibata-Modern-Ice";
  stylix.cursor.size = 18;

  # SOPS secrets — standalone mode decrypts to /run/user/1000/secrets/
  sops.age.keyFile = "/home/none/.config/sops/age/keys.txt";
  sops.defaultSopsFile = ../../secrets/secrets.yaml;
  sops.validateSopsFiles = false;
  sops.secrets = {
    "ssh_keys/id_ed25519_sk" = {
      path = "/home/none/.ssh/id_ed25519_sk";
      mode = "0600";
    };
    "ssh_public_keys/id_ed25519_sk" = {
      path = "/home/none/.ssh/id_ed25519_sk.pub";
      mode = "0644";
    };
    "ssh_certs/id_ed25519_sk-cert" = {
      path = "/home/none/.ssh/id_ed25519_sk-cert.pub";
      mode = "0644";
    };
    "github_token" = {
      mode = "0400";
    };
  };

  home.username = "none";
  home.homeDirectory = "/home/none";
  home.stateVersion = "25.05";
  programs.home-manager.enable = true;
}
