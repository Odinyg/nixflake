{
  lib,
  config,
  pkgs,
  ...
}:
{
  options = {
    postgresql = {
      enable = lib.mkEnableOption "PostgreSQL 17 database server";
    };
  };

  config = lib.mkIf config.postgresql.enable {
    networking.extraHosts = "127.0.0.1 postgres.local";
    services.postgresql = {
      enable = true;
      package = pkgs.postgresql_17;
    };
  };
}
