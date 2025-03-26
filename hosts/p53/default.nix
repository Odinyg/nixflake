{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  ##### Desktop #####

  bspwm.enable = false;
  hyprland.enable = true;
  rofi.enable = true;
  randr.enable = true;
  fonts.enable = true;
  general.enable = true;

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

  ##### Random Desktop Apps #####
  discord.enable = false;
  thunar.enable = true;
  chromium.enable = true;

  #####  Work  ######
  services.onedrive.enable = true;
  _1password.enable = true;
  work.enable = true; # TODO Split into smaller and add/remove/move apps
  programs.dconf.enable = true;
  #####  Code  #####
  git.enable = true;
  direnv.enable = true;

  ##### Everything Else #####
  crypt.enable = false;
  tailscale.enable = true;
  syncthing.enable = false;
  polkit.enable = true;
  utils.enable = true;
  xdg.enable = true;
  virt-man.enable = true;
  # greetd.enable = true;

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

  programs.nix-ld.enable = true;
  services.flatpak.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  xdg.portal.enable = true;
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
  networking.hostName = "VNPC-21"; # Define your hostname.
  networking.networkmanager.enable = true;
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
  services.printing.enable = true;
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
      xdg-desktop-portal-hyprland
      swtpm
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

  nixpkgs.config.allowUnfree = true;
  services.openssh.enable = true;

  system.stateVersion = "24.11"; # Did you read the comment?

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.stable;
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
  boot.kernelParams = lib.optionals (lib.elem "nvidia" config.services.xserver.videoDrivers) [
    "nvidia-drm.modeset=1"
    "nvidia_drm.fbdev=1"
  ];

}
