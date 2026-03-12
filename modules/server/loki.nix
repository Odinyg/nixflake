{
  config,
  lib,
  ...
}:
let
  cfg = config.server.loki;
in
{
  options.server.loki = {
    enable = lib.mkEnableOption "Loki log aggregation";
    port = lib.mkOption {
      type = lib.types.port;
      default = 3100;
      description = "Port for the Loki HTTP API";
    };
  };

  config = lib.mkIf cfg.enable {
    services.loki = {
      enable = true;
      configuration = {
        server.http_listen_port = cfg.port;
        auth_enabled = false;

        common = {
          path_prefix = "/var/lib/loki";
          ring.kvstore.store = "inmemory";
          replication_factor = 1;
        };

        schema_config.configs = [
          {
            from = "2024-01-01";
            store = "tsdb";
            object_store = "filesystem";
            schema = "v13";
            index = {
              prefix = "index_";
              period = "24h";
            };
          }
        ];

        storage_config.filesystem.directory = "/var/lib/loki/chunks";

        query_range.results_cache.cache.embedded_cache = {
          enabled = true;
          max_size_mb = 100;
        };

        limits_config = {
          retention_period = "30d";
          reject_old_samples = true;
          reject_old_samples_max_age = "168h";
        };

        compactor = {
          working_directory = "/var/lib/loki/compactor";
          delete_request_store = "filesystem";
          retention_enabled = true;
        };
      };
    };

    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
