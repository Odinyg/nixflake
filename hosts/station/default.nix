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
  _1password.enable = true;
  work.enable = true;
  kitty.enable = true;
  bspwm.enable = true;
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

  system.stateVersion = "24.05"; # Did you read the comment?

  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };
  services.xserver.videoDrivers = ["nvidia"];
}
