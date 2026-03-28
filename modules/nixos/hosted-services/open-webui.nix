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

    sops.secrets.openwebui_oauth_client_secret = {
      sopsFile = ../../../secrets/station.yaml;
    };

    sops.templates."open-webui-env".content = ''
      OAUTH_CLIENT_SECRET=${config.sops.placeholder.openwebui_oauth_client_secret}
    '';

    services.open-webui = {
      enable = true;
      port = 3000;
      environment = {
        OLLAMA_API_BASE_URL = "http://127.0.0.1:11434";
        WEBUI_AUTH = "true";
        ENABLE_OAUTH_SIGNUP = "true";
        OAUTH_PROVIDER_NAME = "Authelia";
        OAUTH_CLIENT_ID = "open-webui";
        OPENID_PROVIDER_URL = "https://auth.pytt.io/.well-known/openid-configuration";
        OAUTH_SCOPES = "openid profile email";
      };
    };

    systemd.services.open-webui.serviceConfig.EnvironmentFile =
      config.sops.templates."open-webui-env".path;
  };
}
