# Learnings — unify-patterns-and-docs

## 2026-04-12 — Session start, pre-execution

### Module file inventory

**modules/nixos/ root (21 leaf files, all need cfg binding check):**
cosmic.nix, crypt.nix, distributed-builds.nix, fail2ban.nix, fonts.nix, gaming.nix, general.nix, greetd.nix, hyprland.nix, init-net.nix, netbird-client.nix, ollama.nix, password.nix, polkit.nix, secrets.nix, security.nix, styling.nix, sunshine.nix, syncthing.nix, tailscale.nix, virtualization.nix

**modules/nixos/hardware/ (6 files):**
amd-gpu.nix, audio.nix, bluetooth.nix, default.nix (skip — aggregator), nas.nix, wireless.nix

**modules/nixos/work/ (5 files):**
communication.nix, default.nix (has options — parent-child cascade!), development.nix, productivity.nix, remote-access.nix

**modules/nixos/hosted-services/ (3 files):**
default.nix (skip — aggregator), n8n.nix, open-webui.nix

**modules/home-manager/cli/ (leaf .nix files):**
direnv.nix, ghostty.nix, git.nix, kitty.nix, kubernetes.nix, languages.nix, mcp.nix, prompt.nix, system-tools.nix, tmux.nix, xdg.nix, zellij.nix
+ neovim/ (directory — only default.nix has enable option)
+ zsh/ (directory — only default.nix has enable option)

**modules/home-manager/desktop/:**
hyprland/ (directory — only default.nix has enable option)
Dynamic_wallpaper/ (directory — check for enable option)

**modules/home-manager/app/ (leaf .nix files):**
communication.nix, development.nix, discord.nix, lmstudio.nix, media.nix, utilities.nix

**modules/home-manager/misc/ (leaf .nix files):**
chromium.nix, scripts/ (directory), thunar.nix, web-apps.nix, zen-browser.nix

### Gold standard pattern
From modules/server/caddy.nix:
```nix
{ lib, config, pkgs, ... }:
let
  cfg = config.server.caddy;
in
{
  options.server.caddy = {
    enable = lib.mkEnableOption "caddy reverse proxy";
    # other options...
  };

  config = lib.mkIf cfg.enable {
    # ... config
  };
}
```

For nixos/home-manager modules, namespace is root-level:
```nix
let
  cfg = config.<name>;
in
{
  options.<name> = {
    enable = lib.mkEnableOption "...";
  };
  config = lib.mkIf cfg.enable { ... };
}
```

For home-manager modules, config block is additionally wrapped:
```nix
config = lib.mkIf cfg.enable {
  home-manager.users.${config.user} = {
    # user-level config
  };
};
```

### Cross-module refs to NEVER replace
- config.user
- config.sops.*
- config.home-manager.*
- config.smbmount.*
- config.networking.*
- config.services.*
- config.boot.*
- config.programs.*
- config.hardware.*
- config.systemd.*
- config.nix.*
- config.environment.*
- config.xdg.*
- config.i18n.*
- config.time.*
- config.console.*
- config.system.*
- config.virtualisation.*
- inputs.*

### Special cases
- work/default.nix: Setting children (work.communication.enable = lib.mkDefault true;) stays as option name, not cfg
- security.nix: mkMerge — add let cfg, do NOT restructure
- gaming.nix, virtualization.nix: Nested sub-options — config.gaming.steam.enable → cfg.steam.enable (OK)
- neovim/default.nix: Uses mkOption{type=bool} not mkEnableOption — leave as-is, just add cfg binding
