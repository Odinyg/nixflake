{
  config,
  lib,
  ...
}:
let
  cfg = config.server.netbird;
in
{
  options.server.netbird = {
    enable = lib.mkEnableOption "Netbird self-hosted server (management, signal, dashboard, coturn)";
    domain = lib.mkOption {
      type = lib.types.str;
      description = "Public domain for the Netbird server (e.g. netbird.pytt.io)";
    };
    oidcConfigEndpoint = lib.mkOption {
      type = lib.types.str;
      default = "https://auth.pytt.io/.well-known/openid-configuration";
      description = "OIDC discovery endpoint (Authelia)";
    };
  };

  config = lib.mkIf cfg.enable {
    # Sops secrets
    sops.secrets.netbird_datastore_encryption_key = { };
    sops.secrets.netbird_coturn_password = { };

    services.netbird.server = {
      enable = true;
      domain = cfg.domain;
      enableNginx = true;

      management = {
        enable = true;
        domain = cfg.domain;
        oidcConfigEndpoint = cfg.oidcConfigEndpoint;
        turnDomain = cfg.domain;
        dnsDomain = "netbird.selfhosted";
        disableAnonymousMetrics = true;
        settings = {
          DataStoreEncryptionKey = {
            _secret = config.sops.secrets.netbird_datastore_encryption_key.path;
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
              ClientSecret = "";
              AuthorizationEndpoint = "https://auth.pytt.io/api/oidc/authorization";
              TokenEndpoint = "https://auth.pytt.io/api/oidc/token";
              Scope = "openid profile email offline_access";
              RedirectURLs = "http://localhost:53000";
              UseIDToken = false;
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
          AUTH_AUTHORITY = "https://auth.pytt.io";
          AUTH_CLIENT_ID = "netbird";
          AUTH_AUDIENCE = "netbird";
          AUTH_SUPPORTED_SCOPES = "openid profile email";
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
