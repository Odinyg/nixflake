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

  # Temporary: Tailscale for reaching Authelia until Netbird replaces it
  services.tailscale = {
    enable = true;
    extraSetFlags = [ "--accept-routes" ];
  };
  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  # --- Services ---
  server.disko.enable = true;
  server.disko.disk = "/dev/sda";
  server.netbird.enable = true;
  server.netbird.domain = "netbird.pytt.io";

  # Firewall — VPS is public-facing, keep enabled
  # UDP ports (STUN/TURN) are opened automatically by coturn module
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [
    80
    443
    22
  ];

  # ACME / Let's Encrypt for nginx TLS
  security.acme = {
    acceptTerms = true;
    defaults.email = "admin@pytt.io";
  };
  services.nginx.virtualHosts."netbird.pytt.io" = {
    forceSSL = true;
    enableACME = true;
  };

  # Reverse proxy auth.pytt.io to psychosocial via Tailscale (through aerials)
  services.nginx.virtualHosts."auth.pytt.io" = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "https://100.80.149.86";
      proxyWebsockets = true;
      extraConfig = ''
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_ssl_server_name on;
        proxy_ssl_name auth.pytt.io;
      '';
    };
  };

  system.stateVersion = "25.05";
}
