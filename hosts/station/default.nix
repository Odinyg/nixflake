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

  boot.loader.grub = {
    enable = true;
    device = "/dev/nvme0n1";
    useOSProber = true;
  };

  networking.hostName = "station";

  ##### Desktop #####

  # services.desktopManager.cosmic.enable = true;
  # services.displayManager.cosmic-greeter.enable = true;
  programs.nix-ld.enable = true;
  home-manager.backupFileExtension = "backup";
  general.enable = true;
  hyprland.enable = true;
  rofi.enable = true;
  fonts.enable = true;
  ollama.enable = false;
  #### X11 Destktop ###
  randr.enable = false;
  bspwm.enable = false;

  ##### Hardware #####
  audio.enable = true;
  wireless.enable = true;
  zsa.enable = true;
  smbmount.enable = false;
  bluetooth.enable = true;

  ##### CLI #####
  neovim.enable = true;
  zsh.enable = true;
  tmux.enable = true;
  kitty.enable = true;
  termUtils.enable = true;
  zellij.enable = true;
  docker.enable = true;

  ##### Random Desktop Apps #####
  discord.enable = true;
  thunar.enable = true;
  chromium.enable = true;
  game.enable = true;

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
  services.syncthing.enable = true;
  #### AutoMount ####
  services.gvfs.enable = true;
  services.locate.enable = true;

  ##### Theme Color ##### Cant move own module yet check back 23.06.24
  styling.enable = true;
  stylix.enable = true;
  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/nord.yaml";
  stylix.image = ../../modules/home-manager/desktop/hyprland/wallpaper/wallpaper.png;
  stylix.polarity = "dark";
  stylix.opacity.terminal = 0.85;
  stylix.cursor.package = pkgs.bibata-cursors;
  stylix.cursor.name = "Bibata-Modern-Ice";
  stylix.cursor.size = 20;
  stylix.autoEnable = true;
  # home-manager.backupFileExtension = "backup";

  ############## HYPRLAND SETTING################
  ########################################

  environment.systemPackages = [
    pkgs.moonlight-qt
  ];
  users.users.none = {
    shell = pkgs.zsh;
    isNormalUser = true;
    description = "none";
    extraGroups = [
      "networkmanager"
      "wheel"
      "plugdev"
      "docker"
      "kvm"
    ];
  };
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-hyprland
    ];
  };
  xdg.portal.config.common.default = "*";
  services.xserver = {
    enable = true;
    videoDrivers = [ "amdgpu" ];
  };
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  # hardware.nvidia = {
  #   powerManagement.enable = true;
  #   powerManagement.finegrained = false;
  #   package = config.boot.kernelPackages.nvidiaPackages.beta;
  #   modesetting.enable = true;
  #   open = true;
  #   nvidiaSettings = true;
  # };
  services.acpid.enable = true;

  environment.variables = {
    # GBM_BACKEND = "nvidia-drm";
    # WLR_NO_HARDWARE_CURSORS = "1";
    # LIBVA_DRIVER_NAME = "nvidia"; # hardware acceleration
    # __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    # __GL_VRR_ALLOWED = "0";
    # WLR_DRM_NO_ATOMIC = "1";
    # NIXOS_OZONE_WL = "1";
  };

  boot.kernelParams = [
    # "nvidia-drm.modeset=1"
    # "nvidia_drm.fbdev=1"
    # "NVreg_PreserveVideoMemoryAllocations=1"
    # "NVreg_TemporaryFilePath=/var/tmp"
  ];
  system.stateVersion = "25.05";
}
