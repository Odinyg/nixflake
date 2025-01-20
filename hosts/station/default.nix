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
  bspwm.enable = false;
  programs.hyprland.enable = true;
  hyprlandstation.enable = true;
  rofi.enable = true;
  randr.enable = true;
  fonts.enable = true;
  gammastep.enable = false;

  ##### Hardware #####
  audio.enable = true;
  wireless.enable = true;
  zsa.enable = true;
  smbmount.enable = false;

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
  stylix.cursor.size = 18;
  stylix.autoEnable = true;
  home-manager.backupFileExtension = "backup";

  #gtk.enable = false;
  ############## HYPRLAND SETTING################
  ########################################

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
  system.stateVersion = "24.11";
}
