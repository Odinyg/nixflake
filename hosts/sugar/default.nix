{
  pkgs,
  mkServerNetwork,
  inventory,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    (mkServerNetwork {
      ip = inventory.sugar;
      gateway = "10.10.30.1";
    })
  ];

  nixpkgs.config.permittedInsecurePackages = [
    "n8n-1.91.3"
  ];

  # Git credential store for Forgejo (scoped to git.pytt.io only)
  programs.git.enable = true;
  programs.git.config = {
    credential."https://git.pytt.io".helper = "store";
  };

  networking.hostName = "sugar";

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
    backup.enable = true;
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
    redisHost = inventory.truenas;
    redisPort = 30059;
  };
  server.vaultwarden.enable = true;
  server.freshrss = {
    enable = true;
    defaultUser = "homelab";
  };
  server.matrix.enable = true;
  # Migrated to nero — kept declared but disabled. Local checkout under
  # /home/odin/projects/Brain on sugar is left in place as a backup for
  # ~1 week per the migration plan, then removed.
  server.second-brain.enable = false;

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
