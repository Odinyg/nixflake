# Wazuh

**Status:** plan-complete
**Host:** pulse
**Date:** 2026-03-17
**Type:** oci-container

## Research

### NixOS Module
- **Available:** no
- **Module path:** n/a — no `services.wazuh` options exist in nixpkgs-unstable
- **Option coverage:** none

### Image (OCI only)
- **Images:**
  - `wazuh/wazuh-manager:4.14.3` — Wazuh manager (event processing, rules, agent enrollment)
  - `wazuh/wazuh-indexer:4.14.3` — OpenSearch-based indexer (stores alerts/events)
  - `wazuh/wazuh-dashboard:4.14.3` — OpenSearch Dashboards fork (web UI)
- **Web UI Port:** 443 (container), mapped to host port 5601
- **Docs:** https://documentation.wazuh.com/current/deployment-options/docker/wazuh-container.html

### Environment Variables

**Manager:**
- `INDEXER_URL` — indexer endpoint (required)
- `INDEXER_USERNAME` — indexer admin user (required, default: `admin`)
- `INDEXER_PASSWORD` — indexer admin password (required, secret)
- `FILEBEAT_SSL_VERIFICATION_MODE` — cert verification mode (optional, `full`/`none`)
- `SSL_CERTIFICATE_AUTHORITIES` — CA cert path (required for TLS)
- `SSL_CERTIFICATE` — node cert path (required for TLS)
- `SSL_KEY` — node key path (required for TLS)
- `API_USERNAME` — Wazuh API user (default: `wazuh-wui`)
- `API_PASSWORD` — Wazuh API password (required, secret)

**Indexer:**
- `OPENSEARCH_JAVA_OPTS` — JVM heap (default: `-Xms1g -Xmx1g`)
- `bootstrap.memory_lock` — prevent swapping (`true`)
- `network.host` — bind address
- `node.name` — node identifier
- `cluster.initial_cluster_manager_nodes` — cluster bootstrap
- `plugins.security.ssl.*` — TLS certificate paths
- `plugins.security.nodes_dn` — allowed node DNs
- `plugins.security.authcz.admin_dn` — admin cert DNs
- `plugins.security.allow_default_init_securityindex` — allow default security index (`true`)
- `compatibility.override_main_response_version` — compatibility flag (`true`)

**Dashboard:**
- `INDEXER_USERNAME` — indexer admin user (required)
- `INDEXER_PASSWORD` — indexer admin password (required, secret)
- `WAZUH_API_URL` — manager API endpoint (required)
- `DASHBOARD_USERNAME` — dashboard user (default: `kibanaserver`)
- `DASHBOARD_PASSWORD` — dashboard user password (required, secret)
- `API_USERNAME` — Wazuh API user (required)
- `API_PASSWORD` — Wazuh API password (required, secret)
- `SERVER_SSL_ENABLED` — enable HTTPS (`true`)
- `SERVER_SSL_CERTIFICATE` — dashboard TLS cert path
- `SERVER_SSL_KEY` — dashboard TLS key path

### Volumes / Data Paths
- `/var/lib/homelab/wazuh/manager/api_configuration` — manager API config
- `/var/lib/homelab/wazuh/manager/etc` — manager config (ossec.conf)
- `/var/lib/homelab/wazuh/manager/logs` — manager logs
- `/var/lib/homelab/wazuh/manager/queue` — agent event queues
- `/var/lib/homelab/wazuh/manager/var_multigroups` — agent group configs
- `/var/lib/homelab/wazuh/manager/integrations` — custom integrations
- `/var/lib/homelab/wazuh/manager/active-response` — active response logs
- `/var/lib/homelab/wazuh/manager/agentless` — agentless config
- `/var/lib/homelab/wazuh/manager/wodles` — wodles data
- `/var/lib/homelab/wazuh/manager/filebeat_etc` — filebeat config
- `/var/lib/homelab/wazuh/manager/filebeat_var` — filebeat data
- `/var/lib/homelab/wazuh/indexer/data` — OpenSearch data
- `/var/lib/homelab/wazuh/certs` — generated TLS certificates (shared)
- `/var/lib/homelab/wazuh/dashboard/config` — dashboard config overrides

### Database
- **Type:** none (uses OpenSearch/Wazuh indexer for data storage, embedded in the stack)

### Auth
- **Mode:** oidc — Wazuh dashboard supports OpenID Connect via the OpenSearch security plugin; can connect to Authelia as OIDC provider. However, initial setup is complex (requires modifying security config inside the indexer). Start with built-in auth + Authelia forward auth via Caddy, migrate to native OIDC later.
- **Recommended initial approach:** `authelia` (forward auth via Caddy for dashboard access)

### Homepage Widget
- **Available:** no (no native widget in gethomepage)
- **Workaround:** `customapi` widget pointed at Wazuh API `/agents/summary/status` endpoint

### Notes
- Wazuh requires 3 containers (manager, indexer, dashboard) that communicate internally
- The indexer requires `vm.max_map_count = 262144` kernel parameter (OpenSearch requirement)
- Inter-container TLS is required — Wazuh provides a cert generator image (`wazuh/wazuh-certs-generator`) for bootstrapping
- Certificate generation is a one-time init step before first deployment
- Memory: indexer alone needs 1-2 GB heap; plan for 4-6 GB total RAM for the full stack
- Agent enrollment on ports 1514/1515 — only open if LAN agents will connect
- The `iowa` Docker network is used on sugar; pulse needs its own network (e.g., `wazuh`)
- Default admin credentials: `admin`/`SecretPassword` for indexer, `wazuh-wui`/`MyS3cr37P450r.*-` for API — must be changed via secrets
- Dashboard listens on HTTPS inside the container; Caddy should proxy to HTTPS with `tls_insecure_skip_verify` (self-signed internal certs)

---

## Implementation Plan

### File: `modules/server/wazuh.nix` (CREATE)
```nix
{
  config,
  lib,
  ...
}:
let
  cfg = config.server.wazuh;
  certsDir = "/var/lib/homelab/wazuh/certs";
  dataDir = "/var/lib/homelab/wazuh";
in
{
  options.server.wazuh = {
    enable = lib.mkEnableOption "Wazuh XDR/SIEM platform (Docker)";
    dashboardPort = lib.mkOption {
      type = lib.types.port;
      default = 5601;
      description = "Host port for the Wazuh dashboard web UI";
    };
    managerPort = lib.mkOption {
      type = lib.types.port;
      default = 1514;
      description = "Host port for Wazuh agent connections";
    };
    registrationPort = lib.mkOption {
      type = lib.types.port;
      default = 1515;
      description = "Host port for Wazuh agent enrollment";
    };
    apiPort = lib.mkOption {
      type = lib.types.port;
      default = 55000;
      description = "Host port for the Wazuh server API";
    };
    domain = lib.mkOption {
      type = lib.types.str;
      default = "pytt.io";
      description = "Base domain for Wazuh";
    };
  };

  config = lib.mkIf cfg.enable {
    # Secrets
    sops.secrets.wazuh_indexer_password = { };
    sops.secrets.wazuh_api_password = { };
    sops.secrets.wazuh_dashboard_password = { };

    sops.templates."wazuh-manager-env".content = ''
      INDEXER_URL=https://wazuh.indexer:9200
      INDEXER_USERNAME=admin
      INDEXER_PASSWORD=${config.sops.placeholder.wazuh_indexer_password}
      FILEBEAT_SSL_VERIFICATION_MODE=full
      SSL_CERTIFICATE_AUTHORITIES=/etc/ssl/root-ca.pem
      SSL_CERTIFICATE=/etc/ssl/filebeat.pem
      SSL_KEY=/etc/ssl/filebeat-key.pem
      API_USERNAME=wazuh-wui
      API_PASSWORD=${config.sops.placeholder.wazuh_api_password}
    '';

    sops.templates."wazuh-dashboard-env".content = ''
      INDEXER_USERNAME=admin
      INDEXER_PASSWORD=${config.sops.placeholder.wazuh_indexer_password}
      WAZUH_API_URL=https://wazuh.manager
      DASHBOARD_USERNAME=kibanaserver
      DASHBOARD_PASSWORD=${config.sops.placeholder.wazuh_dashboard_password}
      API_USERNAME=wazuh-wui
      API_PASSWORD=${config.sops.placeholder.wazuh_api_password}
      SERVER_SSL_ENABLED=true
      SERVER_SSL_CERTIFICATE=/usr/share/wazuh-dashboard/certs/wazuh-dashboard.pem
      SERVER_SSL_KEY=/usr/share/wazuh-dashboard/certs/wazuh-dashboard-key.pem
    '';

    # Kernel tuning for OpenSearch
    boot.kernel.sysctl."vm.max_map_count" = 262144;

    # Docker
    virtualisation.docker.enable = true;
    virtualisation.oci-containers.backend = "docker";

    # --- Wazuh Manager ---
    virtualisation.oci-containers.containers.wazuh-manager = {
      image = "wazuh/wazuh-manager:4.14.3";
      hostname = "wazuh.manager";
      environmentFiles = [ config.sops.templates."wazuh-manager-env".path ];
      volumes = [
        "${dataDir}/manager/api_configuration:/var/ossec/api/configuration"
        "${dataDir}/manager/etc:/var/ossec/etc"
        "${dataDir}/manager/logs:/var/ossec/logs"
        "${dataDir}/manager/queue:/var/ossec/queue"
        "${dataDir}/manager/var_multigroups:/var/ossec/var/multigroups"
        "${dataDir}/manager/integrations:/var/ossec/integrations"
        "${dataDir}/manager/active-response:/var/ossec/active-response/bin"
        "${dataDir}/manager/agentless:/var/ossec/agentless"
        "${dataDir}/manager/wodles:/var/ossec/wodles"
        "${dataDir}/manager/filebeat_etc:/etc/filebeat"
        "${dataDir}/manager/filebeat_var:/var/lib/filebeat"
        "${certsDir}/root-ca-manager.pem:/etc/ssl/root-ca.pem"
        "${certsDir}/wazuh.manager.pem:/etc/ssl/filebeat.pem"
        "${certsDir}/wazuh.manager-key.pem:/etc/ssl/filebeat-key.pem"
      ];
      ports = [
        "${toString cfg.managerPort}:1514"
        "${toString cfg.registrationPort}:1515"
        "${toString cfg.apiPort}:55000"
      ];
      extraOptions = [ "--network=wazuh" ];
    };

    # --- Wazuh Indexer ---
    virtualisation.oci-containers.containers.wazuh-indexer = {
      image = "wazuh/wazuh-indexer:4.14.3";
      hostname = "wazuh.indexer";
      environment = {
        OPENSEARCH_JAVA_OPTS = "-Xms1g -Xmx1g";
        "bootstrap.memory_lock" = "true";
        "network.host" = "0.0.0.0";
        "node.name" = "wazuh.indexer";
        "cluster.initial_cluster_manager_nodes" = "wazuh.indexer";
        "node.max_local_storage_nodes" = "1";
        "plugins.security.ssl.http.pemcert_filepath" = "/usr/share/wazuh-indexer/certs/wazuh.indexer.pem";
        "plugins.security.ssl.http.pemkey_filepath" = "/usr/share/wazuh-indexer/certs/wazuh.indexer-key.pem";
        "plugins.security.ssl.http.pemtrustedcas_filepath" = "/usr/share/wazuh-indexer/certs/root-ca.pem";
        "plugins.security.ssl.transport.pemcert_filepath" = "/usr/share/wazuh-indexer/certs/wazuh.indexer.pem";
        "plugins.security.ssl.transport.pemkey_filepath" = "/usr/share/wazuh-indexer/certs/wazuh.indexer-key.pem";
        "plugins.security.ssl.transport.pemtrustedcas_filepath" = "/usr/share/wazuh-indexer/certs/root-ca.pem";
        "plugins.security.ssl.http.enabled" = "true";
        "plugins.security.ssl.transport.enforce_hostname_verification" = "false";
        "plugins.security.allow_default_init_securityindex" = "true";
        "compatibility.override_main_response_version" = "true";
        "plugins.security.authcz.admin_dn" = "CN=admin,OU=Wazuh,O=Wazuh,L=California,C=US";
        "plugins.security.check_snapshot_restore_write_privileges" = "true";
        "plugins.security.enable_snapshot_restore_privilege" = "true";
        "plugins.security.nodes_dn" = "CN=wazuh.indexer,OU=Wazuh,O=Wazuh,L=California,C=US";
        "plugins.security.restapi.roles_enabled" = "all_access,security_rest_api_access";
      };
      volumes = [
        "${dataDir}/indexer/data:/var/lib/wazuh-indexer"
        "${certsDir}/root-ca.pem:/usr/share/wazuh-indexer/certs/root-ca.pem"
        "${certsDir}/wazuh.indexer-key.pem:/usr/share/wazuh-indexer/certs/wazuh.indexer-key.pem"
        "${certsDir}/wazuh.indexer.pem:/usr/share/wazuh-indexer/certs/wazuh.indexer.pem"
        "${certsDir}/admin.pem:/usr/share/wazuh-indexer/certs/admin.pem"
        "${certsDir}/admin-key.pem:/usr/share/wazuh-indexer/certs/admin-key.pem"
      ];
      extraOptions = [
        "--network=wazuh"
        "--ulimit=memlock=-1:-1"
        "--ulimit=nofile=65536:65536"
      ];
    };

    # --- Wazuh Dashboard ---
    virtualisation.oci-containers.containers.wazuh-dashboard = {
      image = "wazuh/wazuh-dashboard:4.14.3";
      hostname = "wazuh.dashboard";
      environmentFiles = [ config.sops.templates."wazuh-dashboard-env".path ];
      volumes = [
        "${certsDir}/wazuh.dashboard.pem:/usr/share/wazuh-dashboard/certs/wazuh-dashboard.pem"
        "${certsDir}/wazuh.dashboard-key.pem:/usr/share/wazuh-dashboard/certs/wazuh-dashboard-key.pem"
        "${certsDir}/root-ca.pem:/usr/share/wazuh-dashboard/certs/root-ca.pem"
        "${dataDir}/dashboard/config/opensearch_dashboards.yml:/usr/share/wazuh-dashboard/config/opensearch_dashboards.yml"
        "${dataDir}/dashboard/config/wazuh.yml:/usr/share/wazuh-dashboard/data/wazuh/config/wazuh.yml"
      ];
      ports = [ "${toString cfg.dashboardPort}:5601" ];
      dependsOn = [ "wazuh-indexer" ];
      extraOptions = [ "--network=wazuh" ];
    };

    # Systemd service ordering and homelab target membership
    systemd.services.docker-wazuh-manager = {
      partOf = [ "homelab.target" ];
      wantedBy = [ "homelab.target" ];
    };
    systemd.services.docker-wazuh-indexer = {
      partOf = [ "homelab.target" ];
      wantedBy = [ "homelab.target" ];
    };
    systemd.services.docker-wazuh-dashboard = {
      partOf = [ "homelab.target" ];
      wantedBy = [ "homelab.target" ];
    };

    # Firewall — dashboard for Caddy, agent ports for LAN
    networking.firewall.allowedTCPPorts = [
      cfg.dashboardPort
      cfg.managerPort
      cfg.registrationPort
      cfg.apiPort
    ];

    # Data directories
    systemd.tmpfiles.rules = [
      "d ${dataDir} 0755 root root -"
      "d ${dataDir}/manager 0755 root root -"
      "d ${dataDir}/manager/api_configuration 0755 root root -"
      "d ${dataDir}/manager/etc 0755 root root -"
      "d ${dataDir}/manager/logs 0755 root root -"
      "d ${dataDir}/manager/queue 0755 root root -"
      "d ${dataDir}/manager/var_multigroups 0755 root root -"
      "d ${dataDir}/manager/integrations 0755 root root -"
      "d ${dataDir}/manager/active-response 0755 root root -"
      "d ${dataDir}/manager/agentless 0755 root root -"
      "d ${dataDir}/manager/wodles 0755 root root -"
      "d ${dataDir}/manager/filebeat_etc 0755 root root -"
      "d ${dataDir}/manager/filebeat_var 0755 root root -"
      "d ${dataDir}/indexer 0755 root root -"
      "d ${dataDir}/indexer/data 0755 1000 1000 -"
      "d ${dataDir}/certs 0755 root root -"
      "d ${dataDir}/dashboard 0755 root root -"
      "d ${dataDir}/dashboard/config 0755 root root -"
    ];
  };
}
```

### File: `modules/server/default.nix` (EDIT)

Add to the imports list, in the "Monitoring (pulse)" section:

```nix
    # Monitoring (pulse)
    ./prometheus.nix
    ./loki.nix
    ./grafana.nix
    ./gatus.nix
    ./wazuh.nix
```

### File: `hosts/pulse/default.nix` (EDIT)

Add after the existing service enables:

```nix
  server.wazuh.enable = true;
```

### File: `secrets/pulse.yaml` (REMINDER)
- `wazuh_indexer_password` — admin password for the Wazuh indexer (OpenSearch)
- `wazuh_api_password` — password for the Wazuh API user (`wazuh-wui`)
- `wazuh_dashboard_password` — password for the dashboard `kibanaserver` user

### File: `hosts/psychosocial/default.nix` (EDIT) — Caddy route

Add in the `--- pulse ---` section:

```nix
      @wazuh host wazuh.pytt.io
      handle @wazuh {
        import authelia
        reverse_proxy https://10.10.30.112:5601 {
          transport http {
            tls
            tls_insecure_skip_verify
          }
        }
      }
```

Note: Uses `https` + `tls_insecure_skip_verify` because the Wazuh dashboard serves HTTPS with self-signed certs inside the container. Update IP to `10.10.30.12` after production cutover.

### Manual Steps

1. **Generate TLS certificates** (one-time, on pulse):
   ```bash
   # Clone the wazuh-docker repo for the cert generator config
   cd /tmp && git clone https://github.com/wazuh/wazuh-docker.git -b v4.14.3 --single-branch --depth 1

   # Create the Docker network
   docker network create wazuh

   # Generate certs using the Wazuh cert generator
   docker run --rm -v /var/lib/homelab/wazuh/certs:/certificates \
     -v /tmp/wazuh-docker/single-node/config/wazuh_indexer_ssl_certs/wazuh-certs-generator.yml:/config/certs.yml \
     wazuh/wazuh-certs-generator:0.0.4

   # Fix permissions so containers can read the certs
   chmod -R 644 /var/lib/homelab/wazuh/certs/*
   ```

2. **Create dashboard config files** before first deploy:
   ```bash
   # opensearch_dashboards.yml
   cat > /var/lib/homelab/wazuh/dashboard/config/opensearch_dashboards.yml << 'CONF'
   server.host: 0.0.0.0
   server.port: 5601
   opensearch.hosts: https://wazuh.indexer:9200
   opensearch.ssl.verificationMode: full
   opensearch.username: kibanaserver
   opensearch.password: kibanaserver
   opensearch.requestHeadersAllowlist: ["securitytenant","Authorization"]
   opensearch_security.multitenancy.enabled: false
   opensearch_security.readonly_mode.roles: ["kibana_read_only"]
   server.ssl.enabled: true
   server.ssl.key: "/usr/share/wazuh-dashboard/certs/wazuh-dashboard-key.pem"
   server.ssl.certificate: "/usr/share/wazuh-dashboard/certs/wazuh-dashboard.pem"
   opensearch.ssl.certificateAuthorities: ["/usr/share/wazuh-dashboard/certs/root-ca.pem"]
   uiSettings.overrides.defaultRoute: /app/wz-home
   CONF

   # wazuh.yml
   cat > /var/lib/homelab/wazuh/dashboard/config/wazuh.yml << 'CONF'
   hosts:
     - default:
         url: https://wazuh.manager
         port: 55000
         username: wazuh-wui
         password: wazuh-wui
         run_as: false
   CONF
   ```
   Note: The `password` in `wazuh.yml` is overridden at runtime by the `API_PASSWORD` env var.

3. **Create Docker network** on pulse (if not done during cert generation):
   ```bash
   docker network create wazuh
   ```

4. **Add SOPS secrets**:
   ```bash
   just secrets-pulse
   # Add: wazuh_indexer_password, wazuh_api_password, wazuh_dashboard_password
   # Use strong random passwords (32+ chars)
   ```

5. **After first successful deploy**, change the indexer internal passwords:
   ```bash
   # Exec into the indexer container and run the security admin tool
   # to update the internal users with the passwords from SOPS
   docker exec -it wazuh-indexer bash
   export INSTALLATION_DIR=/usr/share/wazuh-indexer
   OPENSEARCH_PATH_CONF=${INSTALLATION_DIR}/etc/opensearch ${INSTALLATION_DIR}/plugins/opensearch-security/tools/wazuh-passwords-tool.sh --change-all --admin-user admin --admin-password <CURRENT_DEFAULT>
   ```

6. **DNS**: Ensure `wazuh.pytt.io` resolves (Cloudflare wildcard `*.pytt.io` should cover this).

### Verification
- `nix flake check` passes
- `colmena apply --on pulse` deploys
- Web UI accessible at `https://wazuh.pytt.io`
- Agent enrollment test: `curl -k https://10.10.30.112:55000/security/user/authenticate -u wazuh-wui:<password>`
- Dashboard health: `curl -sk https://10.10.30.112:5601/status`

---

## Pre-deploy Checklist
- [ ] Host config updated (`hosts/pulse/default.nix`)
- [ ] Module created (`modules/server/wazuh.nix`)
- [ ] Module imported in `modules/server/default.nix`
- [ ] Firewall ports opened (5601, 1514, 1515, 55000)
- [ ] Secrets added via SOPS (`wazuh_indexer_password`, `wazuh_api_password`, `wazuh_dashboard_password`)
- [ ] TLS certificates generated on pulse
- [ ] Dashboard config files created on pulse
- [ ] Docker network `wazuh` created on pulse
- [ ] Caddy route added on psychosocial (with Authelia forward auth)
- [ ] `vm.max_map_count` set to 262144 (in module)
- [ ] `nix flake check` passes
- [ ] Change default indexer passwords after first boot
