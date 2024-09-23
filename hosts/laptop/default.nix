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

  networking.hostName = "laptop"; 
 ##### Desktop #####
  services.displayManager = {
      defaultSession = "none+bspwm";
      autoLogin.enable = true;
      autoLogin.user = "none";

  };
  services.xserver = {
    enable = true;
    windowManager.bspwm.enable = true;
    displayManager = {
      lightdm = { 
        enable = true; 
      }; 
    };

#### Keyboard Layout ###
    xkb.layout = "us";
    xkb.variant = "";
  };



#  bspwm.enable = true;
# hyprland.enable = true;
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
#greetd.enable = true;

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
programs.hyprland.enable = true;
programs.light.enable = true;
  programs.zsh.enable = true;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  time.timeZone = "Europe/Oslo";
  i18n.defaultLocale = "en_US.UTF-8";
#  programs.zsh.enable = true;
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
      gtk3
      gtk4
      nwg-look
      themix-gui  
      nautilus 
      sxhkd
      bspwm
      rofi
      polybar
      xorg.libX11
      xorg.libX11.dev
      xorg.libxcb
      xorg.libXft
      xorg.libXinerama
      xorg.xinit
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
      libreoffice
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

#fonts = {
#    packages = with pkgs; [
#      noto-fonts
#      noto-fonts-cjk
#      noto-fonts-emoji
#      font-awesome
#      source-han-sans
#      source-han-sans-japanese
#      source-han-serif-japanese
#      (nerdfonts.override { fonts = [ "Meslo" ]; })
#    ];
#    fontconfig = {
#      enable = true;
#      defaultFonts = {
#	      monospace = [ "Meslo LG M Regular Nerd Font Complete Mono" ];
#	      serif = [ "Noto Serif" "Source Han Serif" ];
#	      sansSerif = [ "Noto Sans" "Source Han Sans" ];
#      };
#    };
#};

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [
      "electron-25.9.0"
      "python3.12-youtube-dl-2021.12.17"
      "electron-29.4.6"
    ];
  };
  services.openssh.enable = true;

  system.stateVersion = "24.11"; # Did you read the comment?

}
