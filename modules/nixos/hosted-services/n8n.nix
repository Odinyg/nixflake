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
    networking.extraHosts = "127.0.0.1 n8n.local";
    services.n8n.enable = true;
  };
}
