{
  config,
  lib,
  ...
}:
let
  cfg = config.hosted-services.open-webui;
in
{
  options.hosted-services.open-webui = {
    enable = lib.mkEnableOption "Open WebUI for Ollama";
  };

  config = lib.mkIf cfg.enable {
    networking.extraHosts = "127.0.0.1 open-webui.local";
    services.open-webui = {
      enable = true;
      port = 3000;
      environment = {
        OLLAMA_API_BASE_URL = "http://127.0.0.1:11434";
        WEBUI_AUTH = "true";
      };
    };
  };
}
