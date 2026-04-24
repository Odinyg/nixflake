{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [ ./base.nix ];

  # ==============================================================================
  # DESKTOP ENVIRONMENT & DISPLAY
  # ==============================================================================
  general.enable = true;
  hyprland.enable = true;
  fonts.enable = true;

  # ==============================================================================
  # HARDWARE MODULES
  # ==============================================================================
  audio.enable = true;
  wireless.enable = true;
  bluetooth.enable = true;
  hardware.keyboard.zsa.enable = true;

  # ==============================================================================
  # TERMINAL & CLI TOOLS
  # ==============================================================================
  neovim.enable = true;
  zsh.enable = true;
  prompt.enable = true;
  kitty.enable = true;
  ghostty.enable = true;
  tmux.enable = true;
  system-tools.enable = true;

  # ==============================================================================
  # DEVELOPMENT TOOLS
  # ==============================================================================
  git.enable = true;
  direnv.enable = true;
  languages.enable = true;

  # Development packages needed for building C/C++ projects
  environment.systemPackages = with pkgs; [
    gcc
    gnumake
    pkg-config
    libusb1
  ];

  # ==============================================================================
  # DESKTOP APPLICATIONS
  # ==============================================================================
  thunar.enable = true;
  chromium.enable = true;
  zen-browser.enable = true;
  web-apps.enable = true;
  discord.enable = true;

  # ==============================================================================
  # WORK MODULES
  # ==============================================================================
  _1password.enable = true;
  work.enable = true;

  # ==============================================================================
  # SYSTEM UTILITIES
  # ==============================================================================
  fail2ban-security.enable = lib.mkDefault false;
  tailscale.enable = true;
  netbird-client.enable = true;
  syncthing.enable = true;
  localsend.enable = true;
  polkit.enable = true;
  xdg.enable = true;

  # Application Categories
  kubernetes.enable = true;
  development.enable = true;
  media.enable = true;
  security.enable = true;
  security.insecurePackages.enable = true;
  communication.enable = true;
  utilities.enable = true;
  claudeSkills.enable = true;

  # rustdesk (in utilities) needs /dev/uinput to inject keystrokes on Wayland
  hardware.uinput.enable = true;
  users.users.${config.user}.extraGroups = [
    "input"
    "uinput"
  ];

  # ==============================================================================
  # VIRTUALIZATION
  # ==============================================================================
  virtualization = {
    enable = true;
    docker.rootless = false;
    qemu.virt-manager = true;
    virtualbox.enable = false;
  };

  # ==============================================================================
  # THEME CONFIGURATION
  # ==============================================================================
  styling.enable = true;
  styling.theme = lib.mkDefault "nord";
  styling.polarity = lib.mkDefault "dark";
  styling.opacity.terminal = lib.mkDefault 0.90;
  styling.cursor.size = lib.mkDefault 20;
  styling.autoEnable = lib.mkDefault true;

  # ==============================================================================
  # DESKTOP SERVICES
  # ==============================================================================
  services = {
    acpid.enable = true;
    gvfs.enable = true;
    locate.enable = true;
    printing.enable = true;
    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
  };
}
