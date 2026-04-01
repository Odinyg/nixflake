{ lib, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "spiders";

  # Static IP — Cantabo VPS
  networking.useDHCP = false;
  networking.enableIPv6 = lib.mkForce true;
  networking.interfaces.eth0 = {
    ipv4.addresses = [
      {
        address = "95.111.255.104";
        prefixLength = 20;
      }
    ];
    ipv6.addresses = [
      {
        address = "2a02:c207:2318:6493::1";
        prefixLength = 64;
      }
    ];
  };
  networking.defaultGateway = {
    address = "95.111.240.1";
    interface = "eth0";
  };
  networking.defaultGateway6 = {
    address = "fe80::1";
    interface = "eth0";
  };
  networking.nameservers = [
    "213.136.95.10"
    "213.136.95.11"
    "2a02:c207::1:53"
  ];

  sops.defaultSopsFile = ../../secrets/spiders.yaml;

  # --- Services ---
  server.disko.enable = true;
  server.disko.disk = "/dev/sda";
  server.netbird.enable = true;
  server.netbird.domain = "netbird.pytt.io";
  server.authelia.enable = true;
  server.authelia.listenPort = 9092;

  # Local Redis for Authelia session storage
  server.authelia.redisHost = "127.0.0.1";
  server.authelia.redisPort = 6370;
  services.redis.servers.authelia = {
    enable = true;
    port = 6370;
    bind = "127.0.0.1";
  };

  # Firewall — VPS is public-facing, hardened
  # mkForce to override ports opened by shared server modules (node_exporter 9100, authelia metrics 9959)
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = lib.mkForce [
    22 # SSH
    80 # HTTP (ACME)
    443 # HTTPS (auth + netbird)
    3478 # TURN
    3479 # TURN alt
    5349 # TURNS (TLS)
    5350 # TURNS alt (TLS)
  ];

  # Disable rpcbind — not needed, NFS is for LAN servers only
  services.rpcbind.enable = lib.mkForce false;
  boot.supportedFilesystems = lib.mkForce [ ];

  # SSH hardening — rate limit connections
  services.openssh.settings.MaxAuthTries = 3;

  # Fail2ban for SSH brute force protection
  services.fail2ban = {
    enable = true;
    maxretry = 3;
    bantime = "1h";
    bantime-increment.enable = true;
  };

  # ACME / Let's Encrypt for nginx TLS
  security.acme = {
    acceptTerms = true;
    defaults.email = "admin@pytt.io";
  };
  services.nginx.virtualHosts."netbird.pytt.io" = {
    forceSSL = true;
    enableACME = true;
  };

  # Authelia SSO — served locally on this host
  services.nginx.virtualHosts."auth.pytt.io" = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:9092";
      proxyWebsockets = true;
      extraConfig = ''
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
      '';
    };
  };

  system.stateVersion = "25.05";
}
