{
  config,
  pkgs,
  lib,
  ...
}:
{

  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  networking.hostName = "station";
  time.timeZone = "Europe/Oslo";
  i18n.defaultLocale = "en_US.UTF-8";

  ##### Desktop #####
  bspwm.enable = true;
  programs.hyprland.enable = false;
  hyprlandstation.enable = false;
  rofi.enable = true;
  randr.enable = true;
  fonts.enable = true;
  gammastep.enable = false;

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
  game.enable = true;
  # anbox.enable = true;

  #####  Work  ######
  _1password.enable = false;
  work.enable = true; # TODO Split into smaller and add/remove/move apps

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
  greetd.enable = false;
  services.syncthing.enable = true;
  bluetooth.enable = true;

  ##### Theme Color ##### Cant move own module yet check back 23.06.24
  styling.enable = true;
  stylix.enable = true;
  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/nord.yaml";
  stylix.image = ../../modules/home-manager/desktop/hyprland/wallpaper/wallpaper.png;
  stylix.polarity = "dark";
  stylix.opacity.terminal = 0.85;
  stylix.cursor.package = pkgs.bibata-cursors;
  stylix.cursor.name = "Bibata-Modern-Ice";
  stylix.cursor.size = 18;
  stylix.autoEnable = true;
  home-manager.backupFileExtension = "backup";

  #gtk.enable = false;
  ############## HYPRLAND SETTING################
  nixpkgs.config.allowUnfree = true;
  ########################################

  services.flatpak.enable = true;
  programs.zsh.enable = true;
  users.users.none = {
    shell = pkgs.zsh;
    isNormalUser = true;
    description = "none";
    extraGroups = [
      "networkmanager"
      "wheel"
      "plugdev"
      "docker"
    ];
    packages = with pkgs; [
      firefox
      deluge
      obsidian
      flatpak
      polkit
      ansible
      ansible-lint
      libreoffice
      #     xdg-desktop-portal-hyprland
    ];
  };
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-hyprland
    ];
  };
  nix = {
    package = pkgs.nixFlakes;
    extraOptions = lib.optionalString (
      config.nix.package == pkgs.nixFlakes
    ) "experimental-features = nix-command flakes";
  };

  nixpkgs.config.permittedInsecurePackages = [
    "electron-19.1.9"
    "electron-25.9.0"
    "electron-29.4.6"
    "python3.12-youtube-dl-2021.12.17"
  ];

  services.openssh.enable = true;
  xdg.portal.config.common.default = "*";

  environment.variables = {
    GBM_BACKEND = "nvidia-drm";
    WLR_NO_HARDWARE_CURSORS = "1";
    LIBVA_DRIVER_NAME = "nvidia"; # hardware acceleration
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  };

  boot.kernelParams = lib.optionals (lib.elem "nvidia" config.services.xserver.videoDrivers) [
    "nvidia-drm.modeset=1"
    "nvidia_drm.fbdev=1"
  ];
  hardware.nvidia = {
    #modesetting.enable = true;
    open = false;
    modesetting.enable = true;

    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.beta;
  };

  services.xserver = {
    videoDrivers = [ "nvidia" ];
  };
  system.stateVersion = "24.11";
}
