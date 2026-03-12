{ pkgs, lib, ... }:

{
  imports = [
    # Base
    ./nfs.nix
    ./monitoring.nix
    ./disko.nix
    # Media (byob)
    ./arr.nix
    ./nzbget.nix
    ./transmission.nix
    ./seerr.nix
    # Reverse proxy (psychosocial)
    ./caddy.nix
    ./authelia.nix
    ./homepage.nix
    # Monitoring (pulse)
    ./prometheus.nix
    ./loki.nix
    ./grafana.nix
    ./gatus.nix
    # Database
    ./postgresql.nix
    # Apps (sugar)
    ./n8n.nix
    ./searxng.nix
    ./nextcloud.nix
    ./perplexica.nix
    ./netbootxyz.nix
    ./norish.nix
  ];

  options.server.enable = lib.mkEnableOption "headless server profile";

  config = lib.mkIf true {
    nixpkgs.config.allowUnfree = true;

    # Nix settings
    nix = {
      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        trusted-users = [
          "root"
          "odin"
        ];
        auto-optimise-store = true;
      };
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 14d";
      };
    };

    # Timezone & locale
    time.timeZone = "Europe/Oslo";
    i18n.defaultLocale = "en_US.UTF-8";

    # User
    users.users.odin = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "docker"
      ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINezFWDmtlGHBF674DcsNi+wDMrSp13pNX1lo4RcJTMm odin.nygard@vendanor.com"
      ];
    };

    # Passwordless sudo for wheel (needed for colmena deploys)
    security.sudo.wheelNeedsPassword = false;

    # SSH hardening
    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "prohibit-password";
      };
    };

    # Firewall on by default
    networking.firewall.enable = true;

    # SOPS — use existing age keys
    sops = {
      age.keyFile = "/etc/homelab/sops/keys.txt";
      age.generateKey = false;
    };

    # Host resolution for inter-server communication
    networking.hosts = {
      "10.10.30.10" = [ "psychosocial-old" ];
      "10.10.30.110" = [ "psychosocial" ];
      "10.10.50.10" = [ "byob-old" ];
      "10.10.50.110" = [ "byob" ];
      "10.10.30.11" = [ "sugar-old" ];
      "10.10.30.111" = [ "sugar" ];
      "10.10.30.12" = [ "pulse-old" ];
      "10.10.30.112" = [ "pulse" ];
      "10.10.30.14" = [ "sulfur" ];
      "10.10.10.20" = [ "truenas" ];
    };

    # Common server packages
    environment.systemPackages = with pkgs; [
      vim
      git
      htop
      curl
      jq
    ];

    # Boot — limit generations to prevent /boot filling up
    boot.loader.systemd-boot.configurationLimit = 10;
  };
}
