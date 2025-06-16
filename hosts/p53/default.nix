{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];
  ##### Desktop #####
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal
    ];
  };
  bspwm.enable = true;
  hyprland.enable = true;
  rofi.enable = true;
  randr.enable = true;
  fonts.enable = true;
  general.enable = true;
  programs.kdeconnect.enable = true;

  ##### Hardware #####
  audio.enable = true;
  wireless.enable = true;
  zsa.enable = false;

  ##### CLI #####
  neovim.enable = true;
  zsh.enable = true;
  tmux.enable = true;
  kitty.enable = true;
  termUtils.enable = true;
  zellij.enable = true;

  ##### Random Desktop Apps #####
  discord.enable = false;
  thunar.enable = true;
  chromium.enable = true;

  #####  Work  ######
  onedrive.enable = true;
  _1password.enable = true;
  work.enable = true; # TODO Split into smaller and add/remove/move apps
  programs.dconf.enable = true;
  #####  Code  #####
  git.enable = true;
  direnv.enable = true;

  ##### Everything Else #####
  crypt.enable = false;
  tailscale.enable = true;
  syncthing.enable = true;
  polkit.enable = true;
  utils.enable = true;
  xdg.enable = true;
  virtualization = {
    enable = true;
    qemu.virt-manager = true; # Disable virt-manager GUI
    remoteAccess.enable = true; # Disable Remmina
    virtualbox.enable = false; # Also enable VirtualBox
  };

  ##### Theme Color ##### Cant move own module yet check back 23.06.24
  styling.enable = true;
  styling.theme = "nord";
  styling.polarity = "dark";
  styling.opacity.terminal = 0.90;
  styling.cursor.size = 20;
  styling.autoEnable = true;

  home-manager.backupFileExtension = "backup-$(date +%Y%m%d_%H%M%S)";

  programs.nix-ld.enable = true;
  services.flatpak.enable = true;
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
  boot.loader.grub.configurationLimit = 2;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  networking.hostName = "VNPC-21"; # Define your hostname.
  networking.networkmanager = {
    enable = true;
  };
  time.timeZone = "Europe/Oslo";
  i18n.defaultLocale = "en_US.UTF-8";
  services.trezord.enable = false;

  virtualisation.docker.enable = true;
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };

  #### AutoMount ####
  services.gvfs.enable = true;
  services.locate.enable = true;

  ##############################################

  services.printing = {
    enable = true;
    logLevel = "debug";
    openFirewall = true;
    drivers = [
      pkgs.brlaser
      pkgs.brgenml1lpr
      pkgs.brgenml1cupswrapper
      pkgs.ptouch-driver
      pkgs.gutenprint
      pkgs.cups-filters
      pkgs.ghostscript
    ];
  };

  services.avahi.enable = true;
  services.avahi.nssmdns4 = true;
  services.avahi.openFirewall = true;

  # Enable sound with pipewire.
  nixpkgs.config.permittedInsecurePackages = [
    "electron-19.1.9"
    "electron-29.4.6"
    "python3.12-youtube-dl-2021.12.17"
    "electron-25.9.0"
    "openssl-1.1.1w"
  ];

  users.extraGroups.vboxusers.members = [ "odin" ];
  programs.zsh.enable = true;
  users.users.odin = {
    shell = pkgs.zsh;
    isNormalUser = true;
    description = "odin";
    extraGroups = [
      "lp"
      "docker"
      "networkmanager"
      "wheel"
      "plugdev"
      "polkituser"
    ];
    packages = with pkgs; [
      firefox
      sublime4
      libreoffice
      libsForQt5.okular
      OVMF
      swtpm
      dconf
      obsidian
      flameshot
      satty
      shutter
    ];
  };
  services.teamviewer.enable = true;

  environment.systemPackages = with pkgs; [
    inputs.zen-browser.packages."${pkgs.system}".default
    pciutils
    system-config-printer
    lshw
    python3Packages.brother-ql
    tailscale
  ];

  nixpkgs.config.allowUnfree = true;
  services.openssh.enable = true;

  system.stateVersion = "25.05"; # Did you read the comment?

  services.xserver.videoDrivers = [ "nvidia" ];
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
  environment.variables = {
    GBM_BACKEND = "nvidia-drm";
    WLR_DRM_DEVICES = "$HOME/.config/hypr/card:$HOME/.config/hypr/otherCard";
    WLR_NO_HARDWARE_CURSORS = "1";
    LIBVA_DRIVER_NAME = "nvidia"; # hardware acceleration
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    NIXOS_OZONE_WL = "1";
  };
  boot.kernelParams = [
    "nvidia-drm.modeset=1"
    "nvidia_drm.fbdev=1"
    "fbdev=1"
  ];

}
