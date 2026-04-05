{
  config,
  lib,
  ...
}:
let
  cfg = config.server.matrix;
in
{
  options.server.matrix = {
    enable = lib.mkEnableOption "Matrix homeserver (Conduit)";
    port = lib.mkOption {
      type = lib.types.port;
      default = 6167;
      description = "Port for the Conduit listener";
    };
    serverName = lib.mkOption {
      type = lib.types.str;
      default = "pytt.io";
      description = "Matrix server name (used in @user:server.name identifiers)";
    };
    allowRegistration = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to allow public registration";
    };
    allowFederation = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to federate with other Matrix servers";
    };
    maxRequestSize = lib.mkOption {
      type = lib.types.int;
      default = 20000000;
      description = "Max request size in bytes (default 20MB)";
    };
  };

  config = lib.mkIf cfg.enable {
    services.matrix-conduit = {
      enable = true;
      settings.global = {
        server_name = cfg.serverName;
        port = cfg.port;
        address = "0.0.0.0";
        database_backend = "rocksdb";
        allow_registration = cfg.allowRegistration;
        allow_federation = cfg.allowFederation;
        allow_encryption = true;
        allow_check_for_updates = false;
        max_request_size = cfg.maxRequestSize;
        trusted_servers = [ "matrix.org" ];
      };
    };

    systemd.services.conduit = {
      partOf = [ "homelab.target" ];
      wantedBy = [ "homelab.target" ];
    };
  };
}
