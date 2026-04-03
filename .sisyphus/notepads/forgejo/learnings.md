# Forgejo Plan — Learnings

## [2026-04-03] Session Start: ses_2ac64a375ffe9Ko8bxY79b9oMO

### Codebase Conventions
- Module namespace: `options.server.<name>` with `cfg = config.server.<name>`
- Pattern file: `modules/server/n8n.nix` (the canonical simple NixOS service + postgresql template)
- All systemd services MUST use `partOf = [ "homelab.target" ]` AND `wantedBy = [ "homelab.target" ]`
- Firewall is disabled by default on all servers (`networking.firewall.enable = lib.mkDefault false`)
- sops-nix is the secrets manager (NOT agenix). Templates at `sops.templates."name"`, secrets at `sops.secrets.name`

### PostgreSQL Pattern
- `sops.secrets.postgresql_forgejo_password = { };` — no owner needed (postgres module handles password setting)
- `sops.templates."forgejo-env"` with `FORGEJO__database__PASSWD=${config.sops.placeholder.postgresql_forgejo_password}`
- Load as `serviceConfig.EnvironmentFile = config.sops.templates."forgejo-env".path`
- The `services.forgejo.database.passwordFile` is NOT used — env var approach avoids ownership conflicts

### Forgejo NixOS Module
- `services.forgejo.database.createDatabase = false` — mandatory, we use the codebase's postgresql.nix
- `services.forgejo.database.host = "127.0.0.1"` — TCP not socket
- `HTTP_ADDR = "0.0.0.0"` — required because Caddy is on psychosocial (different host)
- `SSH_DOMAIN = "10.10.30.111"` — sugar's LAN IP for SSH clone URLs
- Admin username cannot be "admin" — using "odin"

### Caddy Pattern (psychosocial)
- Services without Authelia: just `@name host name.pytt.io` + `handle @name { reverse_proxy IP:PORT }`
- Services with Authelia: add `import authelia` before `reverse_proxy`
- Forgejo: NO authelia, but needs `request_body { max_size 1G }` for LFS uploads

### Norish Port Conflict
- Norish default port was 3000, conflicting with Forgejo's desired port
- Resolution: move Norish to 3100 (change `default = 3000;` to `default = 3100;` in norish.nix)
- Norish module is a Docker container (`ports = [ "${toString cfg.port}:3000" ]`) — only host port changes
- **CRITICAL**: psychosocial Caddy config currently routes `@norish` → `10.10.30.111:3000`
  - This MUST be updated to `10.10.30.111:3100` in Task 5 (adding Forgejo Caddy route)
  - Both changes happen in `hosts/psychosocial/default.nix`: update norish + add forgejo
