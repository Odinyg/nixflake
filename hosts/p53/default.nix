# Edit this configuration file to define what should be installed on
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
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "odin" ];
  };
  programs.zsh.enable = true;
  users.users.odin = {
    shell = pkgs.zsh;
    isNormalUser = true;
    description = "none";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      firefox
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
#      nodejs
      openssl
      pavucontrol
      tmux
      synergy 
      xdg-desktop-portal-gtk
      polkit_gnome
      fontconfig
      gnugrep
      # WORK
      teams-for-linux
      teams
      remmina
      ferdium
      dbeaver
      grim
      slurp
      rofi
      polybar
      sxhkd
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
  xorg.xrandr
  pciutils
  arandr
  ];

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = lib.optionalString (config.nix.package == pkgs.nixFlakes)
      "experimental-features = nix-command flakes";
  };




  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  services.openssh.enable = true;

  system.stateVersion = "23.11"; # Did you read the comment?

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {

    # Modesetting is needed most of the time
    modesetting.enable = true;

	# Enable power management (do not disable this unless you have a reason to).
	# Likely to cause problems on laptops and with screen tearing if disabled.
	powerManagement.enable = true;

    # Use the NVidia open source kernel module (which isn't “nouveau”).
    # Support is limited to the Turing and later architectures. Full list of 
    # supported GPUs is at: 
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus 
    # Only available from driver 515.43.04+
    open = true;

    # Enable the Nvidia settings menu,
	# accessible via `nvidia-settings`.
    nvidiaSettings = true;
    
    prime.sync.enable = true;

    prime.nvidiaBusId = "PCI:01:00:0";
    prime.intelBusId = "PCI:00:02:0";
  };
}
