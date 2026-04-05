{
  pkgs,
  ...
}:

{
  imports = [ ./hardware-configuration.nix ];

  nixpkgs.config.permittedInsecurePackages = [
    "n8n-1.91.3"
  ];

  networking.hostName = "sugar";

  # Static IP — staging (change to 10.10.30.11 after cutover)
  networking = {
    useDHCP = false;
    interfaces.ens18 = {
      ipv4.addresses = [
        {
          address = "10.10.30.111";
          prefixLength = 24;
        }
      ];
    };
    defaultGateway = "10.10.30.1";
    nameservers = [
      "10.10.30.1"
      "1.1.1.1"
    ];
  };

  # --- Services ---
  server.disko.enable = true;

  server.postgresql = {
    enable = true;
    databases = [
      "forgejo"
      "mealie"
      "n8n"
      "nextcloud"
      "norish"
      "wger"
      "vaultwarden"
    ];
  };

  server.n8n = {
    enable = true;
    dbHost = "127.0.0.1";
  };
  server.forgejo = {
    enable = true;
    dbHost = "127.0.0.1";
  };
  server.forgejo-runner.enable = true;
  server.searxng.enable = true;
  server.nextcloud = {
    enable = true;
    dbHost = "127.0.0.1:5432";
  };
  server.perplexica.enable = true;
  server.netbootxyz.enable = true;
  server.mealie = {
    enable = true;
    dbHost = "172.18.0.1";
  };
  server.norish = {
    enable = true;
    dbHost = "172.18.0.1";
    redisHost = "172.18.0.1";
  };
  server.wger = {
    enable = true;
    dbHost = "172.18.0.1";
    redisHost = "10.10.10.20";
    redisPort = 30059;
  };
  server.vaultwarden.enable = true;
  server.freshrss = {
    enable = true;
    defaultUser = "homelab";
  };
  server.matrix = {
    enable = true;
    allowRegistration = true; # TEMPORARY — disable after creating users
  };
  server.brain-bot.enable = true;

  # Docker network for inter-container communication
  virtualisation.docker.autoPrune = {
    enable = true;
    dates = "weekly";
  };

  systemd.services.create-sugar-network = {
    serviceConfig.Type = "oneshot";
    wantedBy = [ "multi-user.target" ];
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    script = ''
      ${pkgs.docker}/bin/docker network inspect iowa >/dev/null 2>&1 || \
        ${pkgs.docker}/bin/docker network create iowa
    '';
  };

  # Homelab base directory
  systemd.tmpfiles.rules = [
    "d /var/lib/homelab 0755 root root -"
  ];

  system.stateVersion = "25.05";
}
