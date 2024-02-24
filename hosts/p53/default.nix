
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
  boot.supportedFilesystems = ["ntfs"];
  networking.hostName = "VNPC-21"; # Define your hostname.
 # boot.supportedFilesystems = [ "ntfs" ];
  networking.networkmanager.enable = true;
  time.timeZone = "Europe/Oslo";
  i18n.defaultLocale = "en_US.UTF-8";
  services.trezord.enable = true;

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
  bspwm.enable = false;
  rofi.enable = true;
  randr.enable = true;
  zsa.enable = true;
  tailscale.enable = true;
  chromium.enable = true;
  syncthing.enable = true;
  fonts.enable = true;
  polkit.enable = true;
  hyprland.enable = true;
  xdg.enable = false;
  zellij.enable = false;
  direnv.enable = false;
  services.intune.enable = true;

  #### AutoMount ####
services.gvfs.enable = true; 

##############################################
  services.printing.enable = true;
  # Enable sound with pipewire.
    nixpkgs.config.permittedInsecurePackages = [
    "electron-19.1.9"
    "electron-25.9.0"
    ];

  users.extraGroups.vboxusers.members = [ "odin" ];
  programs.zsh.enable = true;
  users.users.odin = {
    shell = pkgs.zsh;
    isNormalUser = true;
    description = "odin";
    extraGroups = [ "networkmanager" "wheel" "plugdev" ];
    packages = with pkgs; [
      firefox
      sublime
      libreoffice
      syncthing
      teamviewer
      remmina
      intune-portal
      p7zip
      peazip
      xdg-desktop-portal-hyprland
      wl-clipboard
      drawio
      xwayland
      dconf
      filezilla
      rofi-wayland
      thunderbird
      obsidian
      flameshot
      qemu
      # WORK
    #  teams
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
    open = false;
    nvidiaSettings = true;
    prime.sync.enable = true;
    prime.nvidiaBusId = "PCI:1:0:0";
    prime.intelBusId = "PCI:0:2:0";
  };
}
