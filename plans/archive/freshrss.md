# FreshRSS

**Status:** plan-complete
**Host:** sugar
**Date:** 2026-03-15
**Type:** native

## Research

### NixOS Module
- **Available:** yes
- **Module path:** `services.freshrss`
- **Option coverage:** full — enable, baseUrl, defaultUser, passwordFile, database.*, extensions, virtualHost, webserver (nginx/caddy), authType, api.enable, pool, language, dataDir
- **Package version:** 1.28.1 (nixpkgs unstable, updated 2026-03-01)

### Web UI Port
- FreshRSS runs behind php-fpm + nginx (the NixOS module creates both automatically)
- nginx virtualHost will be configured to listen on port **8282** (no conflict with existing sugar services)
- psychosocial's Caddy reverse proxies `freshrss.pytt.io` to `10.10.30.111:8282`

### Environment Variables
- None needed for native NixOS module — all configuration is declarative via `services.freshrss.*` options

### Volumes / Data Paths
- `/var/lib/freshrss` — default data directory (FreshRSS state, user configs, cached content)

### Database
- **Type:** sqlite (default, perfectly adequate for single-user RSS reader — no PostgreSQL overhead needed)

### Auth
- **Mode:** authelia (forward auth via Caddy)
- FreshRSS native OIDC requires Apache + mod_auth_openidc (Docker-only feature), so it is not viable on native NixOS php-fpm
- FreshRSS `authType` will be set to `"none"` since Authelia handles authentication at the Caddy layer
- The Caddy route on psychosocial will use `import authelia` for forward auth
- FreshRSS API paths (`/api/*`) will bypass Authelia so mobile apps and the Homepage widget can authenticate via FreshRSS's own API password

### Homepage Widget
- **Available:** yes
- **Type:** `freshrss`
- **Required fields:** `url`, `username`, `password` (API password, not login password)
- **Allowed fields:** `subscriptions`, `unread`
- **Prerequisite:** `services.freshrss.api.enable = true` — users must then set API passwords in their FreshRSS profile

### Full-Content Article Retrieval

FreshRSS supports retrieving full article content so you can read complete articles without visiting the original site. There are two complementary approaches:

#### Built-in: Article CSS Selector
- Per-feed setting: **Subscription Management > (feed cog) > Advanced > "Article CSS selector on original website"**
- Enter a CSS selector (e.g., `.article-body`, `#content`, `.post-content`) that identifies the main article element on the source website
- FreshRSS fetches the original page and extracts content matching the selector
- Supports multiple selectors separated by commas
- Pros: no extension needed, works out of the box, per-feed granularity
- Cons: requires finding the right selector per site; generates more traffic to source sites; some sites may block repeated requests

#### Extension: freshrss-af-readability
- Uses the Fivefilters Readability.php library to automatically extract article content (same algorithm as Firefox Reader View)
- **No Docker containers or external services required** — runs entirely in PHP
- Requires PHP extensions: dom, xml, curl, mbstring (all available in NixOS php-fpm)
- Enable per-feed after installation
- Not packaged in nixpkgs, but can be installed via `buildFreshRssExtension` or by fetching from GitHub into the extensions directory

#### Recommendation
Use the **built-in CSS selector** approach as the primary method — it requires zero extra dependencies and works natively with the NixOS module. For feeds where the CSS selector is hard to determine, the af_readability extension provides automatic extraction as a fallback.

### Notes
- The NixOS FreshRSS module automatically creates a php-fpm pool and a cron job (`freshrss-updater.timer`) for feed updates
- The nginx virtualHost created by the module needs `listen` overrides to bind to port 8282 instead of the default 80 (port 80 is already used by Nextcloud's nginx on sugar)
- FreshRSS `authType = "none"` disables its internal login form entirely — all auth is handled by Authelia forward auth
- API access (`/api/*`) must bypass Authelia since mobile apps and the Homepage widget need direct token-based auth
- Feed update frequency is controlled by the cron interval (default: every ~30 minutes via systemd timer)

---

## Implementation Plan

### File: `modules/server/freshrss.nix` (CREATE)
```nix
{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.server.freshrss;
in
{
  options.server.freshrss = {
    enable = lib.mkEnableOption "FreshRSS RSS aggregator";
    port = lib.mkOption {
      type = lib.types.port;
      default = 8282;
      description = "Port for the FreshRSS web interface (nginx listener)";
    };
    domain = lib.mkOption {
      type = lib.types.str;
      default = "freshrss.pytt.io";
      description = "Public domain for FreshRSS";
    };
    defaultUser = lib.mkOption {
      type = lib.types.str;
      default = "admin";
      description = "Default admin username";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.freshrss_admin_password = {
      owner = "freshrss";
    };

    services.freshrss = {
      enable = true;
      baseUrl = "https://${cfg.domain}";
      defaultUser = cfg.defaultUser;
      passwordFile = config.sops.secrets.freshrss_admin_password.path;
      authType = "none";
      language = "en";

      api.enable = true;

      database.type = "sqlite";

      virtualHost = cfg.domain;
    };

    # Override nginx to listen on cfg.port instead of 80 (Nextcloud already uses 80)
    services.nginx.virtualHosts.${cfg.domain} = {
      listen = [
        {
          addr = "0.0.0.0";
          port = cfg.port;
        }
      ];
    };

    systemd.services.phpfpm-freshrss = {
      partOf = [ "homelab.target" ];
      wantedBy = [ "homelab.target" ];
    };

    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
```

### File: `modules/server/default.nix` (EDIT)
```nix
# Add to the imports list, in the "Apps (sugar)" section:
    ./freshrss.nix
```

### File: `hosts/sugar/default.nix` (EDIT)
```nix
# Add after the wger block:
  server.freshrss = {
    enable = true;
    defaultUser = "homelab";
  };
```

### File: `secrets/sugar.yaml` (REMINDER)
- `freshrss_admin_password: <password for the default admin user>`

### File: `hosts/psychosocial/default.nix` (EDIT) — Caddy route
```nix
# Add in the "sugar" section of services.caddy.extraConfig, after the @perplexica block:

      @freshrss host freshrss.pytt.io
      handle @freshrss {
        # Strip spoofed auth header from all incoming requests
        request_header -Remote-User

        # API paths bypass Authelia — use FreshRSS's own API password auth
        @freshrss_api path /api/*
        handle @freshrss_api {
          reverse_proxy 10.10.30.111:8282
        }
        # Web UI uses Authelia SSO via forward auth
        handle {
          import authelia
          reverse_proxy 10.10.30.111:8282
        }
      }
```

### File: `modules/server/authelia.nix` (EDIT) — no changes needed
FreshRSS uses `authType = "none"` with Authelia forward auth. No OIDC client registration is needed in Authelia since we are using forward auth (the `import authelia` Caddy snippet), not OIDC. The existing wildcard access control rule `*.pytt.io → one_factor` already covers `freshrss.pytt.io`.

### Manual Steps

1. **Add secret:** Run `just secrets-sugar` and add:
   ```yaml
   freshrss_admin_password: <choose-a-password>
   ```

2. **Deploy sugar:** Commit all changes, then:
   ```bash
   just deploy sugar
   ```

3. **Deploy psychosocial** (for Caddy route):
   ```bash
   just deploy psychosocial
   ```

4. **Configure full-content retrieval per feed:**
   - Log in to `https://freshrss.pytt.io`
   - Go to Subscription Management
   - Click the cog icon next to a feed
   - Under Advanced, enter the CSS selector for that site's article content (e.g., `.article-body`, `#content`)
   - Click the preview button to verify the selector works
   - Save

5. **Set API password** (for Homepage widget / mobile apps):
   - Go to Settings > Profile
   - Set an API password in the "API Management" section

6. **Homepage widget** (optional, add to homepage config):
   ```yaml
   - FreshRSS:
       icon: freshrss.png
       href: https://freshrss.pytt.io
       description: RSS Reader
       widget:
         type: freshrss
         fields: ["unread", "subscriptions"]
         url: http://10.10.30.111:8282
         username: homelab
         password: <api-password>
   ```

### Verification
- `nix flake check` passes
- `colmena apply --on sugar` deploys
- `colmena apply --on psychosocial` deploys (for Caddy route)
- Web UI accessible at `https://freshrss.pytt.io` (redirects through Authelia login)
- API accessible at `https://freshrss.pytt.io/api/` (direct auth, no Authelia)
- Feed updates run automatically via systemd timer
- Full article content retrievable via CSS selector per feed

---

## Pre-deploy Checklist
- [ ] `modules/server/freshrss.nix` created
- [ ] `modules/server/default.nix` updated with import
- [ ] `hosts/sugar/default.nix` updated with `server.freshrss.enable`
- [ ] Firewall port 8282 opened (handled by module)
- [ ] Secret `freshrss_admin_password` added via SOPS
- [ ] Caddy route added on psychosocial (with API bypass for Authelia)
- [ ] No database steps needed (SQLite)
- [ ] Auth configured (Authelia forward auth via Caddy, `authType = "none"`)
- [ ] `nix flake check` passes
