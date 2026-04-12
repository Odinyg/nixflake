{
  lib,
  config,
  pkgs,
  pkgs-unstable,
  ...
}:
let
  cfg = config.ollama;
in
{

  options = {
    ollama = {
      enable = lib.mkEnableOption "ollama";
    };
  };
  config = lib.mkIf cfg.enable {
    networking.extraHosts = "127.0.0.1 ollama.local";

    # Self-signed TLS cert for LAN HTTPS access
    systemd.services.ollama-tls-cert = {
      description = "Generate self-signed TLS cert for Ollama";
      wantedBy = [ "ollama.service" ];
      before = [ "ollama.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        dir="/var/lib/ollama/tls"
        mkdir -p "$dir"
        if [ ! -f "$dir/cert.pem" ] || [ ! -f "$dir/key.pem" ]; then
          ${pkgs.openssl}/bin/openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 \
            -days 3650 -nodes -subj "/CN=ollama" \
            -addext "subjectAltName=IP:10.10.10.10,DNS:ollama.local" \
            -keyout "$dir/key.pem" -out "$dir/cert.pem"
        fi
      '';
    };

    services.ollama = {
      enable = true;
      package = pkgs-unstable.ollama;
      host = "0.0.0.0";
      acceleration = "cuda";
      openFirewall = true;
      environmentVariables = {
        OLLAMA_TLS_CERT = "/var/lib/ollama/tls/cert.pem";
        OLLAMA_TLS_KEY = "/var/lib/ollama/tls/key.pem";
      };
    };
  };
}
