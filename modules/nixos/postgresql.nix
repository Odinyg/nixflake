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
    services.postgresql = {
      enable = true;
      package = pkgs.postgresql_17;
    };
  };
}
