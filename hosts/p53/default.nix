
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
  i18n.defaultLocale = "en_US.UTF-8";
  services.trezord.enable = true;

  discord.enable = true;
  tmux.enable = true;
  crypt.enable = true;
  neovim.enable = true;
  zsh.enable = true;
  thunar.enable = true;
  gammastep.enable = true;
  git.enable = true;
#  xdg.enable = false;
#  zellij.enable = true;
#  direnv.enable = false;
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
  hardware.ledger.enable = true;
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
  virtualisation.virtualbox.host.enable = true;
  users.extraGroups.vboxusers.members = [ "none" ];
  nixpkgs.config.virtualbox.enableExtensionPack = true;
  programs.steam = {
  enable = true;
  remotePlay.openFirewall = true;
  dedicatedServer.openFirewall = true;
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
      vscode
      filezilla
      go
      acpilight
      google-chrome
      remmina
      thunderbird
      kitty
      unzip
      git
      gcc
      gh
      obsidian
      flatpak
      flameshot
      syncthingtray
      syncthing
      protonup-ng
      qemu
      st
      stdenv
      plocate
      ripgrep
      killall
      fzf
      xfce.thunar
      burpsuite
      virt-manager
      feh
      networkmanagerapplet
      etcher
      openssl
      pavucontrol
      xdg-desktop-portal-gtk
      polkit_gnome
      fontconfig
      gnugrep
      xorg.xbacklight
      gvfs
      # WORK
    #  teams
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
