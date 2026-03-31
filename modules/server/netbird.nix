{
  config,
  lib,
  ...
}:
let
  cfg = config.server.netbird;
  authDomain = "auth.pytt.io";
in
{
  options.server.netbird = {
    enable = lib.mkEnableOption "Netbird self-hosted server (management, signal, dashboard, coturn)";
    domain = lib.mkOption {
      type = lib.types.str;
      description = "Public domain for the Netbird server (e.g. netbird.pytt.io)";
    };
  };

  config = lib.mkIf cfg.enable {
    # Sops secrets
    sops.secrets.netbird_datastore_encryption_key = { };
    sops.secrets.netbird_coturn_password = {
      owner = "turnserver";
    };
    sops.secrets.netbird_oidc_client_secret = { };

    services.netbird.server = {
      enable = true;
      domain = cfg.domain;
      enableNginx = true;

      management = {
        enable = true;
        domain = cfg.domain;
        oidcConfigEndpoint = "https://${authDomain}/.well-known/openid-configuration";
        turnDomain = cfg.domain;
        dnsDomain = "netbird.selfhosted";
        disableAnonymousMetrics = true;
        settings = {
          DataStoreEncryptionKey = {
            _secret = config.sops.secrets.netbird_datastore_encryption_key.path;
          };
          HttpConfig = {
            AuthIssuer = "https://${authDomain}";
          };
          TURNConfig = {
            Turns = [
              {
                Proto = "udp";
                URI = "turn:${cfg.domain}:3478";
                Username = "netbird";
                Password = {
                  _secret = config.sops.secrets.netbird_coturn_password.path;
                };
              }
            ];
            Secret = {
              _secret = config.sops.secrets.netbird_coturn_password.path;
            };
            TimeBasedCredentials = false;
          };
          PKCEAuthorizationFlow = {
            ProviderConfig = {
              Audience = "netbird";
              ClientID = "netbird";
              ClientSecret = {
                _secret = config.sops.secrets.netbird_oidc_client_secret.path;
              };
              AuthorizationEndpoint = "https://${authDomain}/api/oidc/authorization";
              TokenEndpoint = "https://${authDomain}/api/oidc/token";
              Scope = "openid profile email offline_access";
              RedirectURLs = [ "http://localhost:53000" ];
              UseIDToken = true;
            };
          };
          DeviceAuthorizationFlow = {
            Provider = "none";
          };
          IdpManagerConfig = {
            ManagerType = "none";
          };
        };
      };

      signal = {
        enable = true;
      };

      dashboard = {
        enable = true;
        settings = {
          AUTH_AUTHORITY = "https://${authDomain}";
          AUTH_CLIENT_ID = "netbird";
          AUTH_AUDIENCE = "netbird";
          AUTH_SUPPORTED_SCOPES = "openid profile email";
          AUTH_REDIRECT_URI = "/auth";
          AUTH_SILENT_REDIRECT_URI = "/silent-auth";
          USE_AUTH0 = false;
          NETBIRD_TOKEN_SOURCE = "idToken";
        };
      };

      coturn = {
        enable = true;
        domain = cfg.domain;
        passwordFile = config.sops.secrets.netbird_coturn_password.path;
      };
    };

    # systemd homelab.target membership
    systemd.services.netbird-management = {
      partOf = [ "homelab.target" ];
      wantedBy = [ "homelab.target" ];
    };

    systemd.services.netbird-signal = {
      partOf = [ "homelab.target" ];
      wantedBy = [ "homelab.target" ];
    };

    systemd.services.coturn = {
      partOf = [ "homelab.target" ];
      wantedBy = [ "homelab.target" ];
    };

    systemd.services.nginx = {
      partOf = [ "homelab.target" ];
      wantedBy = [ "homelab.target" ];
    };
  };
}
