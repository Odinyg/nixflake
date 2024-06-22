{ config, pkgs,lib, ... }: {

  imports =
    [ 
      ./hardware-configuration.nix
    ];

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  networking.hostName = "Station"; 
  time.timeZone = "Europe/Oslo";
  i18n.defaultLocale = "en_US.UTF-8";

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
  _1password.enable = false;
  work.enable = true;
  kitty.enable = true;
  bspwm.enable = false;
  hyprland.enable = true;
  rofi.enable = true;
  randr.enable = true;
  zsa.enable = true;
  game.enable = true;
  tailscale.enable = true;
  chromium.enable = true;
  syncthing.enable = true;
  fonts.enable = true;
  polkit.enable = true;
  xdg.enable = false;
  zellij.enable = false;
  direnv.enable = false;
  #gtk.enable = false;
  services.syncthing.enable = true;
  ############## HYPRLAND SETTING################

  stylix.enable = true;
  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/nord.yaml";
#  stylix.base16scheme = "${pkgs.base16-Scheme}/share/themes/porple.yaml";
  stylix.image = ../../modules/home-manager/desktop/hyprland/wallpaper.png;
  stylix.autoEnable = true;
  ########################################

  programs.zsh.enable = true;
  users.users.none= {
    shell = pkgs.zsh;
    isNormalUser = true;
    description = "none";
    extraGroups = [ "networkmanager" "wheel" "plugdev" ];
    packages = with pkgs; [
      firefox
      deluge
      obsidian
      flatpak
      polkit
      ansible
      ansible-lint
      libreoffice
      xdg-desktop-portal-hyprland
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
    extraOptions = lib.optionalString (config.nix.package == pkgs.nixFlakes)
      "experimental-features = nix-command flakes";
  };

  nixpkgs.config = { 
      allowUnfree = true;
      permittedInsecurePackages = [ "electron-25.9.0" ];
    };
  services.openssh.enable = true;

  system.stateVersion = "24.11"; 
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


  services.xserver ={ 
    videoDrivers = ["nvidia"];
  };
}
