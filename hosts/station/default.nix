{ config, pkgs,lib, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };
  networking = {
    hostName = "Station"; # Define your hostName
  };
  time.timeZone = "Europe/Oslo";
  i18n.defaultLocale = "en_US.UTF-8";
  utils.enable = true;
  discord.enable = true;
  tmux.enable = true;
  crypt.enable = true;
  neovim.enable = true;
  zsh.enable = true;
  thunar.enable = true;
  gammastep.enable = true;
  git.enable = true;
  audio.enable = true;
  wireless.enable = true;
  _1password.enable = true;
  work.enable = true;
  kitty.enable = true;
  bspwm.enable = true;
  rofi.enable = true;
  randr.enable = true;
  zsa.enable = true;
  game.enable = true;
  tailscale.enable = true;
#  xdg.enable = false;
#  zellij.enable = true;
#  direnv.enable = false;



services.devmon.enable = true;
services.gvfs.enable = true; 
services.udisks2.enable = true;
  # Enable sound with pipewire.

  security.polkit.enable = true;
 systemd = {
  user.services.polkit-gnome-authentication-agent-1 = {
    description = "polkit-gnome-authentication-agent-1";
    wantedBy = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
  };
     extraConfig = ''
     DefaultTimeoutStopSec=10s
   '';
};
  services.tailscale = {
    enable = true;

  };
  programs.zsh.enable = true;
  users.users.none= {
    shell = pkgs.zsh;
    isNormalUser = true;
    description = "none";
    extraGroups = [ "networkmanager" "wheel" "plugdev" ];
    packages = with pkgs; [
      firefox
      google-chrome
      gcc
      deluge
      obsidian
      flatpak
      syncthingtray
      syncthing
      protonup-ng
      networkmanagerapplet
      pavucontrol
      polkit_gnome
      fontconfig
      gvfs
      betterlockscreen
    ];
  };

fonts = {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji
      font-awesome
      source-han-sans
      source-han-sans-japanese
      source-han-serif-japanese
      nerdfonts
    ];
    fontconfig = {
      enable = true;
      defaultFonts = {
	      monospace = [ "Meslo LG M Regular Nerd Font Complete Mono" ];
	      serif = [ "Noto Serif" "Source Han Serif" ];
	      sansSerif = [ "Noto Sans" "Source Han Sans" ];
      };
    };
};


  nix = {
    package = pkgs.nixFlakes;
    extraOptions = lib.optionalString (config.nix.package == pkgs.nixFlakes)
      "experimental-features = nix-command flakes";
  };

  nixpkgs = {
    config = { 
      allowUnfree = true;
      permittedInsecurePackages = [
        "electron-25.9.0"
      ];
    };
    
  };
  services.openssh.enable = true;

  system.stateVersion = "24.05"; # Did you read the comment?

  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };
  services.xserver.videoDrivers = ["nvidia"];
}
