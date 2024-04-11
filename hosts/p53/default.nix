
{ config, pkgs,lib, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
  networking.hostName = "VNPC-21"; # Define your hostname.
  networking.networkmanager.enable = true;
  time.timeZone = "Europe/Oslo";
  i18n.defaultLocale = "en_US.UTF-8";
  services.trezord.enable = true;

  utils.enable = true;
  virt-man.enable = true;
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
  tailscale.enable = true;
  chromium.enable = true;
  syncthing.enable = true;
  fonts.enable = true;
  polkit.enable = true;
  hyprland.enable = false;
  xdg.enable = false;
  zellij.enable = false;
  direnv.enable = false;

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
      libsForQt5.okular
      virt-manager
      OVMF
      swtpm
      syncthing
      
      teamviewer
      remmina
      intune-portal
 #     peazip
      drawio
      dconf
      filezilla
      thunderbird
      obsidian
      flameshot
      qemu
      betterlockscreen
      ventoy-full
    ];
  };
   services.teamviewer.enable = true;

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

  system.stateVersion = "24.05"; # Did you read the comment?

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
