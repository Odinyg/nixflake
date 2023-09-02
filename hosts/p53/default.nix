# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ inputs, config, pkgs,nixvim,lib, ... }:

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
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Oslo";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Enable the X11 windowing system.
#  services.xserver.enable = true;
 # services.picom.enable = true;
 # Enable the GNOME Desktop Environment.
 # services.xserver.windowManager.bspwm.enable = true;
  programs.hyprland = {
      enable = true;
      xwayland.enable = true;
      enableNvidiaPatches = true;
      package = inputs.hyprland.packages.${pkgs.system}.hyprland;
  };
  programs.waybar.enable = true;
  # Configure keymap in X11
 # services.xserver = {
 #   layout = "us";
 #   xkbVariant = "";
 # };
  # Enable CUPS to print documents.
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
      firefox-wayland
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
#      powershell
      protonup-ng
      qemu
      st
      xfce.thunar
      stdenv
      virt-manager
      feh
      vim
      plocate
#      nodejs
      openssl
      pavucontrol
      tmux
#      xdg-desktop-portal-gtk
#      polkit_gnome
      fontconfig
      gnugrep

      # WORK
      teams
      remmina
      ferdium
      ungoogled-chromium
      wofi
    ];
  };

fonts = {
    fonts = with pkgs; [
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
  ];

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = lib.optionalString (config.nix.package == pkgs.nixFlakes)
      "experimental-features = nix-command flakes";
  };
#  nix.settings.experimental-features = [
#    "nix-command"
#    "flakes"
#  ];




  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;



  services.openssh.enable = true;

  system.stateVersion = "23.05"; # Did you read the comment?

}
