{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.server.postgresql;
  isLocalOnly = cfg.listenAddresses == "localhost" || cfg.listenAddresses == "127.0.0.1";
in
{
  options.server.postgresql = {
    enable = lib.mkEnableOption "PostgreSQL database server";
    port = lib.mkOption {
      type = lib.types.port;
      default = 5432;
      description = "Port for PostgreSQL";
    };
    databases = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "List of databases to create (each gets a matching user with ownership)";
      example = [
        "n8n"
        "nextcloud"
        "norish"
      ];
    };
    listenAddresses = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0";
      description = "Addresses to listen on (use 'localhost' for local-only)";
    };
    allowedNetworks = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "10.10.0.0/16"
        "172.16.0.0/12"
      ];
      description = "Networks allowed to connect via password auth";
    };
    backup = {
      enable = lib.mkEnableOption "daily PostgreSQL backup";
      dir = lib.mkOption {
        type = lib.types.str;
        default = "/var/backup/postgresql";
        description = "Directory for backup dumps";
      };
      retention = lib.mkOption {
        type = lib.types.int;
        default = 7;
        description = "Number of daily backups to retain";
      };
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        services.postgresql = {
          enable = true;
          package = pkgs.postgresql_16;
          settings = {
            port = cfg.port;
            listen_addresses = lib.mkForce cfg.listenAddresses;
          };

          ensureDatabases = cfg.databases;

          ensureUsers = map (db: {
            name = db;
            ensureDBOwnership = true;
          }) cfg.databases;

          # Replace default pg_hba.conf entirely: peer for local socket, scram-sha-256 for TCP
          authentication = lib.mkForce (
            ''
              # Local socket — peer auth (system user = db user)
              local all all              peer
              # Localhost TCP — password auth
              host  all all 127.0.0.1/32 scram-sha-256
              host  all all ::1/128      scram-sha-256
            ''
            + lib.concatMapStringsSep "\n" (net: "host  all all ${net}       scram-sha-256") cfg.allowedNetworks
          );
        };

        systemd.services.postgresql = {
          partOf = [ "homelab.target" ];
          wantedBy = [ "homelab.target" ];
        };

        # Set passwords from sops secrets after every postgresql start
        systemd.services.postgresql-set-passwords = {
          after = [ "postgresql.service" ];
          requires = [ "postgresql.service" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig.Type = "oneshot";
          script = lib.concatMapStringsSep "\n" (db: ''
            pw=$(cat /run/secrets/postgresql_${db}_password)
            /run/wrappers/bin/sudo -u postgres ${config.services.postgresql.package}/bin/psql -v pw="$pw" \
              <<< "ALTER ROLE \"${db}\" PASSWORD :'pw'"
          '') cfg.databases;
        };

        # Sops secrets for each database user password
        sops.secrets = lib.listToAttrs (
          map (db: {
            name = "postgresql_${db}_password";
            value = {
              owner = lib.mkDefault "postgres";
              group = lib.mkDefault "postgres";
              mode = lib.mkDefault "0440";
            };
          }) cfg.databases
        );

        # Prometheus postgres exporter
        services.prometheus.exporters.postgres = {
          enable = true;
          port = 9187;
          runAsLocalSuperUser = true;
          openFirewall = true;
        };

        # Only open firewall if listening on non-localhost
        networking.firewall.allowedTCPPorts = lib.mkIf (!isLocalOnly) [ cfg.port ];
      }
      (lib.mkIf cfg.backup.enable {
        systemd.tmpfiles.rules = [
          "d ${cfg.backup.dir} 0750 postgres postgres -"
        ];

        systemd.services.postgresql-backup = {
          description = "PostgreSQL daily backup";
          partOf = [ "homelab.target" ];
          wantedBy = [ "homelab.target" ];
          serviceConfig = {
            Type = "oneshot";
            User = "postgres";
          };
          script = ''
            set -euo pipefail
            timestamp=$(date +%Y%m%d-%H%M%S)
            tmpfile="${cfg.backup.dir}/.dump-in-progress.sql.gz"
            finalfile="${cfg.backup.dir}/pg_dumpall-$timestamp.sql.gz"
            ${config.services.postgresql.package}/bin/pg_dumpall | gzip > "$tmpfile"
            mv "$tmpfile" "$finalfile"
            find "${cfg.backup.dir}" -name 'pg_dumpall-*.sql.gz' -mtime +${toString cfg.backup.retention} -delete
          '';
        };

        systemd.timers.postgresql-backup = {
          description = "Daily PostgreSQL backup timer";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = "*-*-* 03:00:00";
            Persistent = true;
          };
        };
      })
    ]
  );
}
