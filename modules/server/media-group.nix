{
  config,
  lib,
  ...
}:
let
  cfg = config.server.media-group;
in
{
  options.server.media-group = {
    enable = lib.mkEnableOption "shared media group for arr/download services";
    gid = lib.mkOption {
      type = lib.types.int;
      default = 1000;
      description = "GID for the media group";
    };
  };

  config = lib.mkIf cfg.enable {
    users.groups.media.gid = cfg.gid;
  };
}
