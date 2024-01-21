#]; Edim this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs,lib, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/mnt/boot/efi";
  networking.hostName = "VNPC-21"; # Define your hostname.
 # boot.supportedFilesystems = [ "ntfs" ];
  networking.networkmanager.enable = true;
  time.timeZone = "Europe/Oslo";
  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

###### Configure X11 and WindowManager ######## 

  services.xserver = {
    enable = true;
    windowManager.bspwm.enable = true;
    displayManager = {
      defaultSession = "none+bspwm";
      autoLogin.enable = true;
      autoLogin.user = "odin";
      lightdm = { 
        enable = true; 
      }; 
    };
#### Keyboard Layout ###
    layout = "us";
    xkbVariant = "";
  };
  services.tlp.enable = false; 
  services.picom.enable = true;
  #### AutoMount ####
services.devmon.enable = true;
services.gvfs.enable = true; 
services.udisks2.enable = true;

##############################################
  services.printing.enable = true;
  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  hardware.acpilight.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
    nixpkgs.config.permittedInsecurePackages = [
    "electron-19.1.9"
    "electron-25.9.0"
    ];
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
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "odin" ];
  };
  services.flatpak.enable = true;
  xdg.portal = {
    enable = true;
    extraPortals = [pkgs.xdg-desktop-portal-gtk];
  };
  services.tailscale = {
    enable = true;

  };

  programs.zsh.enable = true;
  users.users.odin = {
    shell = pkgs.zsh;
    isNormalUser = true;
    description = "none";
    extraGroups = [ "networkmanager" "wheel" "plugdev" ];
    packages = with pkgs; [
      firefox
      sublime
      expect
      vscode
      libreoffice
      go
      acpilight
      google-chrome
      remmina
      thunderbird
      kitty
      xclip
      unzip
      git
      gcc
      gh
      obsidian
      flatpak
      flameshot
      ripgrep
      syncthingtray
      syncthing
      protonup-ng
      qemu
      st
      fzf
      xfce.thunar
      stdenv
      virt-manager
      feh
      plocate
      killall
      networkmanagerapplet
      inetutils 
      etcher
      meld
#      nodejs
      openssl
      pavucontrol
      tmux
      synergy 
      xdg-desktop-portal-gtk
      polkit_gnome
      fontconfig
      gnugrep
      xorg.xbacklight
      gvfs
      # WORK
    #  teams
      teams-for-linux
      anydesk
      remmina
      ferdium
      dbeaver
      onlyoffice-bin
      grim
      slurp
      rofi
      polybar
      sxhkd
      ledger-live-desktop
      betterlockscreen
      ventoy-full
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

  environment.systemPackages = with pkgs; [
  autorandr
  openvpn
  networkmanager-openvpn

  xorg.xrandr
  pciutils
  lshw
  arandr
  tailscale
  ];

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = lib.optionalString (config.nix.package == pkgs.nixFlakes)
      "experimental-features = nix-command flakes";
  };

  nixpkgs.config.allowUnfree = true;
  services.openssh.enable = true;

  system.stateVersion = "23.11"; # Did you read the comment?

  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };
  services.xserver.videoDrivers = ["nvidia"];
  hardware.nvidia = {
    modesetting.enable = true;
	powerManagement.enable = false;
    open = true;
    nvidiaSettings = true;
    prime.sync.enable = true;
    prime.nvidiaBusId = "PCI:1:0:0";
    prime.intelBusId = "PCI:0:2:0";
  };
}
