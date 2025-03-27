{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader = {

    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };
  networking.hostName = "laptop";
  ##### Desktop #####
  programs.steam.enable = true;

  general.enable = true;
  services.playerctld.enable = true;
  hyprland.enable = true;
  rofi.enable = true;
  randr.enable = true;
  fonts.enable = true;

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
  bluetooth.enable = true;

  ##### Random Desktop Apps #####
  discord.enable = true;
  thunar.enable = true;
  chromium.enable = true;

  #####  Work  ######
  _1password.enable = true;
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

  stylix.fonts = {
    sizes.applications = 14;
    serif = {
      package = pkgs.dejavu_fonts;
      name = "DejaVu Serif";
    };

    sansSerif = {
      package = pkgs.dejavu_fonts;
      name = "DejaVu Sans";
    };

    monospace = {
      package = pkgs.dejavu_fonts;
      name = "DejaVu Sans Mono";
    };

    emoji = {
      package = pkgs.noto-fonts-emoji;
      name = "Noto Color Emoji";
    };
  };

  home-manager.backupFileExtension = "backup";
  programs.nix-ld.enable = true;
  services.flatpak.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  programs.zsh.enable = true;
  time.timeZone = "Europe/Oslo";
  i18n.defaultLocale = "en_US.UTF-8";
  services.gvfs.enable = true;
  services.locate.enable = true;
  #  programs.zsh.enable = true;
  services.printing.enable = true;
  users.users.none = {
    shell = pkgs.zsh;
    isNormalUser = true;
    description = "none";
    extraGroups = [
      "networkmanager"
      "docker"
      "plugdev"
      "polkotuser"
      "wheel"
    ];
    packages = with pkgs; [
      google-chrome
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

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [
      #     "electron-25.9.0"
      #     "python3.12-youtube-dl-2021.12.17"
      #     "electron-29.4.6"
    ];
  };
  services.openssh.enable = true;

  system.stateVersion = "25.05"; # Did you read the comment?

}
