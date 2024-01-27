
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
    networkmanager.enable = true;
  };
  time.timeZone = "Europe/Oslo";
  i18n.defaultLocale = "en_US.UTF-8";
  services.trezord.enable = true;

###### Configure X11 and WindowManager ######## 

  services.xserver = {
    enable = true;
    windowManager.bspwm.enable = true;
    displayManager = {
      defaultSession = "none+bspwm";
      autoLogin.enable = true;
      autoLogin.user = "none";
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
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
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
  hardware.ledger.enable = true;
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "none" ];
  };
  services.flatpak.enable = true;
  xdg.portal = {
    enable = true;
    extraPortals = [pkgs.xdg-desktop-portal-gtk];
  };
  services.tailscale = {
    enable = true;

  };
  virtualisation.virtualbox.host.enable = true;
  users.extraGroups.vboxusers.members = [ "none" ];
  programs.steam = {
  enable = true;
  remotePlay.openFirewall = true;
  dedicatedServer.openFirewall = true;
  };
  programs.zsh.enable = true;
  users.users.none= {
    shell = pkgs.zsh;
    isNormalUser = true;
    description = "none";
    extraGroups = [ "networkmanager" "wheel" "plugdev" ];
    packages = with pkgs; [
      firefox
      sublime
      expect
      vscode
      filezilla
      go
      google-chrome
      remmina
      thunderbird
      kitty
      xclip
      unzip
      git
      gcc
      gh
      deluge
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
      burpsuite
      virt-manager
      feh
      plocate
      killall
      networkmanagerapplet
      inetutils 
      etcher
#      nodejs
      openssl
      pavucontrol
      tmux
      synergy 
      xdg-desktop-portal-gtk
      polkit_gnome
      fontconfig
      gnugrep
      gitkraken
      xorg.xbacklight
      gvfs
      # WORK
    #  teams
      discord
      libreoffice
      teams-for-linux
      anydesk
      remmina
      ferdium
      dbeaver
      onlyoffice-bin
      rofi
      polybar
      sxhkd
      ledger-live-desktop
      betterlockscreen
      dbeaver
      nmap
      #Gaming
      lutris
      wine64
      steam

      steamPackages.steam
      steam-run
      wine
      #Cryptro
      trezor-suite
      ledger-live-desktop
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

  nixpkgs = {
    config = { 
      allowUnfree = true;
      permittedInsecurePackages = [
        "electron-19.1.9"
        "electron-25.9.0"
      ];
      virtualbox.enableExtensionPack = true;

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
