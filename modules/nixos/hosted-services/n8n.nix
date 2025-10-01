{
  config,
  lib,
  ...
}:
let
  cfg = config.hosted-services.n8n;
in
{
  options.hosted-services.n8n = {
    enable = lib.mkEnableOption "n8n workflow automation service";
  };

  config = lib.mkIf cfg.enable {
    services.n8n.enable = true;
  };
}