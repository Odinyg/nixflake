{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  user = "odin";
  home = {
    username = "odin";
    homeDirectory = "/home/odin";
    stateVersion = "25.05";
  };

  programs.home-manager.enable = true;

  # Desktop environment - Only configs for Hyprland, Waybar, and Rofi
  # These modules will only manage configuration files, not install packages
  hyprland.enable = true;
  waybar.enable = true;
  rofi.enable = true;

  # Theming
  stylix = {
    enable = true;
    polarity = "dark";
    image = ../../modules/home-manager/desktop/hyprland/config/wallpapers/nord-rainbow-dark-nix.png;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/nord.yaml";
    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Ice";
      size = 24;
    };
    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font Mono";
      };
      sansSerif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Sans";
      };
      serif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Serif";
      };
      sizes = {
        applications = 12;
        terminal = 11;
        desktop = 11;
        popups = 10;
      };
    };
  };

  home.packages = with pkgs; [
    # From original user packages
    rclone
    tree
    libva-utils
    glxinfo
    vulkan-tools
    wayland-utils
    kdePackages.kate
    screen
    # From original system packages
    pciutils
    lshw
    tailscale
    # Common utilities
    wget
    curl
    unzip
    ripgrep
    fd
    jq
    yq
    htop
    ncdu
    duf
    dust
    procs
    tldr
    neofetch
    # Development
    gh
    lazygit
    docker-compose
  ];

  programs.ssh = {
    enable = true;
    addKeysToAgent = "yes";
    extraConfig = ''
      AddKeysToAgent yes
    '';
  };

  programs.git = {
    userName = "odin";
    userEmail = "git@pytt.io";
  };
}

