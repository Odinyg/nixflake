# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by prunninrg ‘nixos-help’).

{ pkgs,... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
#      inputs.home-manager.nixosModules.default
    ];
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
  hyprland.enable = false;
  rofi.enable = true;
  randr.enable = true;
  zsa.enable = true;
  tailscale.enable = true;
  chromium.enable = true;
  syncthing.enable = true;
  fonts.enable = true;
  polkit.enable = true;
#  firefox.enable = true;
#  xdg.enable = false;
  #zellij.enable = true;
#  direnv.enable = false;

  programs.zsh.enable = true;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  time.timeZone = "Europe/Oslo";
  i18n.defaultLocale = "en_US.UTF-8";
#  programs.zsh.enable = true;
  xdg.portal = {
    enable = true;
    config.common.default = "gtk";
    extraPortals = [pkgs.xdg-desktop-portal-gtk];
  };
  services.printing.enable = true;
  users.users.none = {
    shell = pkgs.zsh;
    isNormalUser = true;
    description = "none";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      google-chrome
      gcc
      vlc
      xdg-desktop-portal-gtk
      tailscale
      deluge
      obsidian
      flatpak
      flameshot
      protonup-ng
      virt-manager
      feh
      killall
      pavucontrol
      polkit_gnome
#      sxhkd
#      bspwm
 #     rofi
#      polybar
    ];
  };
  security.polkit.enable = true;
 systemd = {
  user.services.polkit-gnome-authentication-agent-1 = {
    description = "polkit-gnome-authentication-agent-1";
    wantedBy = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
  };
   extraConfig = ''
     DefaultTimeoutStopSec=10s
   '';
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
      (nerdfonts.override { fonts = [ "Meslo" ]; })
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

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [
      "electron-25.9.0"
    ];
  };
  services.openssh.enable = true;

  system.stateVersion = "24.05"; # Did you read the comment?

}
