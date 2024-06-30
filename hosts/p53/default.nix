
{ config, pkgs,lib, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];



  ##### Desktop #####
  bspwm.enable = false;
  hyprland.enable = true;
  rofi.enable = false;
  randr.enable = true;
  fonts.enable = true;
  gammastep.enable = false;
  programs.hyprland.enable = true;
  
  ##### Hardware #####
  audio.enable = true;
  wireless.enable = true;
  zsa.enable = true;

  ##### CLI #####
  neovim.enable = true;
  zsh.enable = true;
  tmux.enable = true;
  kitty.enable = true;
  termUtils.enable = true;

  ##### Random Desktop Apps #####
  discord.enable = true;
  thunar.enable = true;
  chromium.enable = true;
  
  #####  Work  ######
  _1password.enable = false;
  work.enable = true;        #TODO Split into smaller and add/remove/move apps
  
  #####  Code  #####
  git.enable = true;
  direnv.enable = true;

  ##### Everything Else #####
  crypt.enable = true;
  tailscale.enable = true;
  syncthing.enable = true;
  polkit.enable = true;
  utils.enable = true;
  xdg.enable = true;
  virt-man.enable = true;
  greetd.enable = true;

  ##### Theme Color ##### Cant move own module yet check back 23.06.24
  styling.enable = true;
  stylix.enable = true;
  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/nord.yaml";
  stylix.image = ../../modules/home-manager/desktop/hyprland/wallpaper/wallpaper.png;
  stylix.polarity = "dark";
  stylix.opacity.terminal = 0.92;
  stylix.cursor.package = pkgs.bibata-cursors;
  stylix.cursor.name = "Bibata-Modern-Ice";
  stylix.cursor.size = 18;
  home-manager.backupFileExtension = "backup";


  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
  networking.hostName = "VNPC-21"; # Define your hostname.
  networking.networkmanager.enable = true;
  time.timeZone = "Europe/Oslo";
  i18n.defaultLocale = "en_US.UTF-8";
  services.trezord.enable = true;

  virtualisation.docker.enable = true;

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
    extraGroups = [ "docker" "networkmanager" "wheel" "plugdev" ];
    packages = with pkgs; [
      firefox
      sublime
      libreoffice
      libsForQt5.okular
      OVMF
      xdg-desktop-portal-hyprland
      
      swtpm
      syncthing
      drawio
      dconf
      obsidian
      flameshot
    ];
  };
   services.teamviewer.enable = true;

  environment.systemPackages = with pkgs; [
  pciutils
  lshw
  tailscale
  ];

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = lib.optionalString (config.nix.package == pkgs.nixFlakes)
      "experimental-features = nix-command flakes";
  };

  nixpkgs.config.allowUnfree = true;
  services.openssh.enable = true;

  system.stateVersion = "24.11"; # Did you read the comment?

  services.xserver.videoDrivers = ["nvidia"];
  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.beta;
    modesetting.enable = true;
	powerManagement.enable = false;
    open = true;
    nvidiaSettings = true;
    prime.sync.enable = true;
    prime.nvidiaBusId = "PCI:1:0:0";
    prime.intelBusId = "PCI:0:2:0";
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    WLR_DRM_DEVICES = "$HOME/.config/hypr/card";

  };
}
