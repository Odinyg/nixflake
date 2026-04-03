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
    ./ntfy.nix
    # Database
    ./postgresql.nix
    # Apps (sugar)
    ./n8n.nix
    ./searxng.nix
    ./nextcloud.nix
    ./perplexica.nix
    ./netbootxyz.nix
    ./mealie.nix
    ./norish.nix
    ./wger.nix
    ./freshrss.nix
    ./forgejo.nix
    # VPN / overlay network (spiders)
    ./netbird.nix
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

    # Firewall disabled for cross-subnet debugging (override per-host for public VPS)
    networking.firewall.enable = lib.mkDefault false;

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
      kitty.terminfo
    ];

    # Homelab service grouping target
    systemd.targets.homelab = {
      description = "All homelab services";
      wantedBy = [ "multi-user.target" ];
    };

    # Netbird client — mesh VPN for inter-server communication
    services.netbird.enable = true;
    networking.firewall.trustedInterfaces = [ "wt0" ];

    # IP forwarding — needed for NetBird routing peers to forward LAN traffic
    boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

    # systemd-resolved for proper split DNS (Netbird registers via D-Bus)
    services.resolved.enable = true;

    # Monitoring on all servers (log + metric collection → pulse)
    server.monitoring.enable = lib.mkDefault true;

    # Boot — limit generations to prevent /boot filling up
    boot.loader.systemd-boot.configurationLimit = 10;
  };
}
