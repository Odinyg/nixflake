# Omarchy Scouting Report: Cool Patterns for NixOS Flake

**Project**: [basecamp/omarchy](https://github.com/basecamp/omarchy) — Beautiful, Modern & Opinionated Linux by DHH  
**Current Version**: v3.5.1 (Apr 16, 2026)  
**Language**: Bash (89.8%), CSS, Go Template, Lua, Python  
**Philosophy**: Opinionated, batteries-included Arch-based desktop with sensible defaults + user customization

---

## Executive Summary

Omarchy is a **highly opinionated, production-grade desktop environment** built on Arch Linux with Hyprland. It bundles 219 utility scripts, 19 themes, and a sophisticated configuration system that separates defaults from user customizations. The project demonstrates several patterns worth porting to NixOS:

1. **Layered config system** (defaults → user overrides → dynamic toggles)
2. **Comprehensive utility CLI** (omarchy-* commands with semantic prefixes)
3. **Theme system** with color palette abstraction and multi-app theming
4. **Smart application launching** (launch-or-focus, web app installer)
5. **Hyprland workflow enhancements** (window popping, gaps toggling, transparency)
6. **Dynamic feature toggles** (stored as sourced config files)
7. **Migration system** for breaking changes
8. **Hardware detection** with exit-code-based conditionals

---

## 1. HYPRLAND CONFIG TWEAKS & WORKFLOW

### 1.1 Layered Config System ⭐⭐⭐
**What it does**: Separates immutable defaults from user customizations via `source` directives.

**Structure**:
```
~/.config/hypr/hyprland.conf (user entry point)
  ├─ source ~/.local/share/omarchy/default/hypr/autostart.conf
  ├─ source ~/.local/share/omarchy/default/hypr/bindings/*.conf
  ├─ source ~/.local/share/omarchy/default/hypr/envs.conf
  ├─ source ~/.config/omarchy/current/theme/hyprland.conf (theme-specific)
  └─ source ~/.config/hypr/{monitors,input,bindings,looknfeel,autostart}.conf (user overrides)
```

**Why it's cool**: User can override ANY setting without touching defaults. Defaults are always available for reference. Theme switching atomically swaps entire config subtree.

**NixOS portability**: **EASY** — Use `home.file` to generate layered configs, `xdg.configHome` for paths.

---

### 1.2 Window Popping (Float & Pin) ⭐⭐
**What it does**: Toggle a window to float, resize, center, pin, and tag it as "pop" layer.

**Command**: `omarchy-hyprland-window-pop [width height [x y]]`

**Usage**: Super+O to pop out a tiled window (e.g., Spotify, chat) to stay fixed on display.

**Implementation** ([source](https://github.com/basecamp/omarchy/blob/dev/bin/omarchy-hyprland-window-pop)):
```bash
hyprctl dispatch togglefloating address:$addr
hyprctl dispatch resizeactive exact $width $height address:$addr
hyprctl dispatch centerwindow address:$addr
hyprctl dispatch pin address:$addr
hyprctl dispatch alterzorder top address:$addr
hyprctl dispatch tagwindow +pop address:$addr
```

**Why it's cool**: Solves the "I want this window to always float but stay on this monitor" problem elegantly.

**NixOS portability**: **EASY** — Port as a home-manager script, bind in Hyprland config.

---

### 1.3 Dynamic Toggles (Persistent Hyprland Flags) ⭐⭐⭐
**What it does**: Store Hyprland config snippets as files in `~/.local/state/omarchy/toggles/hypr/`, sourced by main config.

**Example**: `omarchy-hyprland-toggle window-no-gaps`
- If `~/.local/state/omarchy/toggles/hypr/window-no-gaps.conf` exists → delete it (disable)
- If not → copy from `$OMARCHY_PATH/default/hypr/toggles/window-no-gaps.conf` (enable)
- Then `hyprctl reload`

**Why it's cool**: Toggles persist across reboots without editing config files. Can be bound to keybindings.

**NixOS portability**: **MEDIUM** — Requires runtime state directory + systemd service to manage toggles.

---

### 1.4 Comprehensive Keybinding System ⭐⭐
**What it does**: Uses `bindd` (Hyprland's documented keybinding with descriptions) for all bindings.

**Features**:
- Semantic prefixes: `SUPER`, `SUPER SHIFT`, `SUPER ALT`, `SUPER CTRL`
- Descriptions for each binding (shown in help menu)
- Organized into separate files: `media.conf`, `clipboard.conf`, `tiling-v2.conf`, `utilities.conf`
- Application bindings with `omarchy-launch-*` helpers

**Example bindings**:
```
bindd = SUPER, RETURN, Terminal, exec, uwsm-app -- xdg-terminal-exec --dir="$(omarchy-cmd-terminal-cwd)"
bindd = SUPER SHIFT, F, File manager, exec, uwsm-app -- nautilus --new-window
bindd = SUPER, O, Pop window out, exec, omarchy-hyprland-window-pop
bindd = SUPER, L, Toggle workspace layout, exec, omarchy-hyprland-workspace-layout-toggle
```

**Why it's cool**: Bindings are self-documenting. Easy to generate help menu from descriptions.

**NixOS portability**: **EASY** — Generate via Nix, bind in Hyprland module.

---

### 1.5 Monitor Scaling Cycle ⭐
**What it does**: Cycle through display scales (1 → 1.6 → 2 → 3 → 1) on focused monitor.

**Command**: `omarchy-hyprland-monitor-scaling-cycle`

**Why it's cool**: Useful for laptops with high-DPI displays or when connecting external monitors.

**NixOS portability**: **EASY** — Port as script, bind to keybinding.

---

### 1.6 Internal Monitor Toggle ⭐
**What it does**: Toggle laptop internal display on/off (useful for presentations or external-only mode).

**Command**: `omarchy-hyprland-monitor-internal-toggle`

**Safety**: Won't disable if it's the only active display.

**NixOS portability**: **EASY** — Port as script.

---

### 1.7 Window Transparency Toggle ⭐
**What it does**: Toggle opacity for focused window.

**Command**: `omarchy-hyprland-active-window-transparency-toggle`

**Implementation**:
```bash
hyprctl dispatch setprop "address:$(hyprctl activewindow -j | jq -r '.address')" opaque toggle
```

**NixOS portability**: **EASY** — One-liner script.

---

### 1.8 Workspace Layout Toggle ⭐
**What it does**: Toggle between tiling layouts (dwindle ↔ master).

**Command**: `omarchy-hyprland-workspace-layout-toggle`

**NixOS portability**: **EASY** — Script wrapper around `hyprctl dispatch`.

---

## 2. WAYBAR STATUS BAR SETUP

### 2.1 Modular Waybar Config ⭐⭐
**What it does**: Organizes waybar into logical sections with custom modules.

**Structure**:
```jsonc
{
  "modules-left": ["custom/omarchy", "hyprland/workspaces"],
  "modules-center": ["clock", "custom/update", "custom/voxtype", "custom/screenrecording-indicator"],
  "modules-right": ["group/tray-expander", "bluetooth", "network", "pulseaudio", "cpu", "battery"]
}
```

**Custom modules**:
- `custom/omarchy` — Menu button with tooltip
- `custom/update` — Shows if updates available (signal-based refresh)
- `custom/voxtype` — Voice typing status
- `custom/screenrecording-indicator` — Shows when recording
- `custom/idle-indicator` — Shows idle state
- `custom/notification-silencing-indicator` — DND status

**Why it's cool**: Minimal, clean bar with only essential info. Custom modules integrate with omarchy ecosystem.

**NixOS portability**: **EASY** — Generate via Nix, use `programs.waybar` module.

---

### 2.2 Workspace Persistence ⭐
**Waybar config**:
```jsonc
"persistent-workspaces": {
  "1": [], "2": [], "3": [], "4": [], "5": []
}
```

**Why it's cool**: Ensures workspaces 1-5 always exist, even if empty.

**NixOS portability**: **EASY** — Set in waybar config.

---

## 3. APPLICATION LAUNCHER (WALKER)

### 3.1 Walker Configuration ⭐⭐⭐
**What it does**: Configures Walker (Wayland app launcher) with prefix-based providers.

**Config** (`~/.config/walker/config.toml`):
```toml
theme = "omarchy-default"
additional_theme_location = "~/.local/share/omarchy/default/walker/themes/"

[providers]
default = ["desktopapplications", "websearch"]

[[providers.prefixes]]
prefix = "/"      # List all providers
prefix = "."      # File search
prefix = ":"      # Symbols/emoji
prefix = "="      # Calculator
prefix = "@"      # Web search
prefix = "$"      # Clipboard history
```

**Why it's cool**: Single launcher with context-aware providers. Prefix system is intuitive.

**NixOS portability**: **EASY** — Generate via Nix, use `programs.walker` module.

---

### 3.2 Walker Launcher Script ⭐
**What it does**: Ensures elephant (data provider) and walker service are running before launching.

**Command**: `omarchy-launch-walker`

**Implementation**:
```bash
if ! pgrep -x elephant > /dev/null; then
  setsid uwsm-app -- elephant &
fi
if ! pgrep -f "walker --gapplication-service" > /dev/null; then
  setsid uwsm-app -- env GSK_RENDERER=cairo walker --gapplication-service &
fi
exec walker --width 644 --maxheight 300 --minheight 300 "$@"
```

**Why it's cool**: Handles service startup transparently. GSK_RENDERER=cairo avoids GPU issues.

**NixOS portability**: **EASY** — Port as script.

---

## 4. THEMING SYSTEM

### 4.1 Multi-Theme Support ⭐⭐⭐
**What it does**: Bundles 19 pre-built themes with consistent color palette structure.

**Themes**: catppuccin, catppuccin-latte, ethereal, everforest, flexoki-light, gruvbox, hackerman, kanagawa, lumon, matte-black, miasma, nord, osaka-jade, retro-82, ristretto, rose-pine, tokyo-night, vantablack, white

**Theme structure** (per theme):
```
themes/catppuccin/
├── colors.toml          # Color palette (accent, foreground, background, color0-15)
├── hyprland.conf        # Hyprland theme config
├── hyprlock.conf        # Lockscreen colors
├── waybar.css           # Waybar styling
├── btop.theme           # System monitor theme
├── neovim.lua           # Neovim colorscheme
├── vscode.json          # VS Code settings
├── icons.theme          # Icon theme name
├── backgrounds/         # Theme-specific wallpapers
└── preview.png          # Theme preview image
```

**Why it's cool**: Consistent color palette across ALL apps. Easy to add new themes.

**NixOS portability**: **MEDIUM** — Requires theme generation system + per-app theme setters.

---

### 4.2 Atomic Theme Switching ⭐⭐⭐
**What it does**: Swaps entire theme directory atomically to avoid partial updates.

**Command**: `omarchy-theme-set <theme-name>`

**Implementation**:
```bash
# Setup clean next theme directory
rm -rf "$NEXT_THEME_PATH"
mkdir -p "$NEXT_THEME_PATH"

# Copy official theme, then overlay user customizations
cp -r "$OMARCHY_THEMES_PATH/$THEME_NAME/"* "$NEXT_THEME_PATH/"
cp -r "$USER_THEMES_PATH/$THEME_NAME/"* "$NEXT_THEME_PATH/"

# Generate dynamic configs (templates)
omarchy-theme-set-templates

# Swap atomically
rm -rf "$CURRENT_THEME_PATH"
mv "$NEXT_THEME_PATH" "$CURRENT_THEME_PATH"

# Restart all components
omarchy-restart-waybar
omarchy-restart-swayosd
omarchy-restart-terminal
omarchy-restart-hyprctl
omarchy-restart-btop
omarchy-restart-opencode
omarchy-restart-mako

# Update app-specific themes
omarchy-theme-set-gnome
omarchy-theme-set-browser
omarchy-theme-set-vscode
omarchy-theme-set-obsidian
omarchy-theme-set-keyboard
```

**Why it's cool**: No partial theme states. User customizations overlay official themes. All apps update in sync.

**NixOS portability**: **HARD** — Requires runtime theme switching + per-app theme setters. Better to use Stylix.

---

### 4.3 Template System for Dynamic Configs ⭐⭐
**What it does**: Uses `{{ variable }}` placeholders in theme configs, replaced at theme-set time.

**Example**: `default/themed/hyprlock.conf.tpl`
```
background {
  color = {{ background }}
}
input-field {
  inner_color = {{ inner_color }}
  outer_color = {{ outer_color }}
  font_color = {{ font_color }}
}
```

**Why it's cool**: Single source of truth for colors. No duplication across theme files.

**NixOS portability**: **EASY** — Use Nix string interpolation instead of templates.

---

## 5. DEFAULT APP CHOICES & INTEGRATION

### 5.1 Smart Application Launching ⭐⭐⭐
**What it does**: Provides semantic launchers that handle app-specific logic.

**Commands**:
- `omarchy-launch-browser` — Open browser (respects private mode flag)
- `omarchy-launch-editor` — Open editor
- `omarchy-launch-or-focus <pattern> [command]` — Launch or focus existing window
- `omarchy-launch-or-focus-tui <app>` — Launch TUI app in terminal
- `omarchy-launch-or-focus-webapp <name> <url>` — Launch web app
- `omarchy-launch-floating-terminal-with-presentation` — Terminal for demos
- `omarchy-launch-walker` — App launcher with service management

**Example** (`omarchy-launch-or-focus`):
```bash
WINDOW_PATTERN="$1"
LAUNCH_COMMAND="${2:-"uwsm-app -- $WINDOW_PATTERN"}"
WINDOW_ADDRESS=$(hyprctl clients -j | jq -r --arg p "$WINDOW_PATTERN" \
  '.[]|select((.class|test("\\b" + $p + "\\b";"i")) or (.title|test("\\b" + $p + "\\b";"i")))|.address' | head -n1)

if [[ -n $WINDOW_ADDRESS ]]; then
  hyprctl dispatch focuswindow "address:$WINDOW_ADDRESS"
else
  eval exec setsid $LAUNCH_COMMAND
fi
```

**Why it's cool**: Prevents duplicate app instances. Integrates with Hyprland window management.

**NixOS portability**: **EASY** — Port as home-manager scripts.

---

### 5.2 Web App Installer ⭐⭐⭐
**What it does**: Create `.desktop` files for web apps with auto-favicon fetching.

**Command**: `omarchy-webapp-install [name url icon-url]`

**Interactive mode**:
```bash
APP_NAME=$(gum input --prompt "Name> " --placeholder "My favorite web app")
APP_URL=$(gum input --prompt "URL> " --placeholder "https://example.com")
FAVICON_URL="https://www.google.com/s2/favicons?domain=${APP_URL}&sz=128"
curl -fsSL -o "$ICON_DIR/$APP_NAME.png" "$FAVICON_URL"
```

**Generated `.desktop` file**:
```ini
[Desktop Entry]
Name=ChatGPT
Exec=omarchy-launch-webapp https://chatgpt.com
Icon=/home/user/.local/share/applications/icons/ChatGPT.png
Type=Application
```

**Why it's cool**: Turns any web app into a launchable desktop app. Auto-fetches favicon.

**NixOS portability**: **EASY** — Port as script, generate `.desktop` files via Nix.

---

### 5.3 Default App Bindings ⭐
**Omarchy defaults**:
- Terminal: `xdg-terminal-exec` (respects XDG defaults)
- Browser: Brave (with flags for privacy)
- Editor: Neovim (via `omarchy-launch-editor`)
- File manager: Nautilus
- Music: Spotify (via `omarchy-launch-or-focus`)
- Chat: Signal Desktop
- Notes: Obsidian
- Email: Hey.com (web app)
- Chat GPT: ChatGPT (web app)

**Why it's cool**: All apps are launchable via keybindings. Easy to customize.

**NixOS portability**: **EASY** — Set via home-manager.

---

## 6. POWER-USER WORKFLOWS

### 6.1 Screenshot with Editor Integration ⭐⭐⭐
**What it does**: Take screenshot, optionally edit with Satty, save to ~/Pictures.

**Command**: `omarchy-cmd-screenshot [smart|region|window] [slurp|grim] [--editor=satty]`

**Features**:
- Smart mode: Detect if user wants region or window
- Auto-creates output directory
- Integrates with Satty for annotation
- Respects `OMARCHY_SCREENSHOT_DIR` and `XDG_PICTURES_DIR`

**Why it's cool**: One command for all screenshot needs. Satty integration for quick edits.

**NixOS portability**: **EASY** — Port as script, bind to Print key.

---

### 6.2 Screen Recording with Webcam Overlay ⭐⭐⭐
**What it does**: Record screen with optional desktop audio, microphone, and webcam overlay.

**Command**: `omarchy-cmd-screenrecord [--with-desktop-audio] [--with-microphone-audio] [--with-webcam] [--resolution=WxH]`

**Features**:
- Auto-detects webcam
- Scales webcam overlay to monitor DPI
- Caps resolution to 4K
- Saves to ~/Videos
- Respects `OMARCHY_SCREENRECORD_DIR`

**Why it's cool**: Professional-grade screen recording with minimal setup.

**NixOS portability**: **MEDIUM** — Requires gstreamer + ffmpeg integration.

---

### 6.3 File/Folder Sharing via LocalSend ⭐⭐
**What it does**: Share clipboard, files, or folders via LocalSend (LAN file transfer).

**Command**: `omarchy-cmd-share [clipboard|file|folder]`

**Implementation**:
```bash
systemd-run --user --quiet --collect localsend --headless send "$FILES"
```

**Why it's cool**: Integrates LocalSend into keybinding system. No manual app launching.

**NixOS portability**: **EASY** — Port as script, requires LocalSend package.

---

### 6.4 OCR & Color Picker ⭐
**What it does**: Omarchy bundles scripts for OCR and color picking (via Satty).

**Commands**:
- `omarchy-cmd-screenshot` with Satty → color picker built-in
- OCR via Tesseract (implied by screenshot workflow)

**Why it's cool**: Power-user tools integrated into screenshot workflow.

**NixOS portability**: **EASY** — Port as scripts.

---

## 7. NOTIFICATION DAEMON (MAKO)

### 7.1 Mako Configuration ⭐
**What it does**: Configures Mako notification daemon with theme-aware styling.

**Features**:
- Theme-aware colors (sourced from `colors.toml`)
- Notification silencing toggle (`omarchy-toggle-notification-silencing`)
- Indicator in waybar

**Why it's cool**: Notifications match theme. Can be silenced via keybinding.

**NixOS portability**: **EASY** — Use `services.mako` module.

---

## 8. LOCKSCREEN & IDLE HANDLING

### 8.1 Hypridle Configuration ⭐⭐
**What it does**: Configures idle timeouts with progressive actions.

**Config**:
```
listener {
  timeout = 150  # 2.5min
  on-timeout = pidof hyprlock || omarchy-launch-screensaver
}

listener {
  timeout = 151  # 5min
  on-timeout = loginctl lock-session
}

listener {
  timeout = 330  # 5.5min
  on-timeout = brightnessctl -sd '*::kbd_backlight' set 0
  on-resume = brightnessctl -rd '*::kbd_backlight'
}

listener {
  timeout = 330  # 5.5min
  on-timeout = hyprctl dispatch dpms off
  on-resume = hyprctl dispatch dpms on && brightnessctl -r
}
```

**Why it's cool**: Progressive idle handling (screensaver → lock → backlight off → display off).

**NixOS portability**: **EASY** — Use `services.hypridle` module.

---

### 8.2 Hyprlock Configuration ⭐⭐
**What it does**: Configures lockscreen with theme-aware colors and animations.

**Features**:
- Theme-sourced colors
- Fingerprint auth support (auto-disabled if not available)
- Password input with visual feedback
- Blur background

**Why it's cool**: Minimal, fast lockscreen. Integrates with system auth.

**NixOS portability**: **EASY** — Use `programs.hyprlock` module.

---

## 9. BUNDLED SCRIPTS & UTILITIES

### 9.1 Semantic Command Naming ⭐⭐⭐
**What it does**: All 219 commands follow semantic prefixes for discoverability.

**Prefixes**:
- `cmd-` — Utility commands (check if commands exist, misc)
- `pkg-` — Package management
- `hw-` — Hardware detection (exit codes for conditionals)
- `refresh-` — Copy default config to user's `~/.config/`
- `restart-` — Restart a component
- `launch-` — Open applications
- `install-` — Install optional software
- `setup-` — Interactive setup wizards
- `toggle-` — Toggle features on/off
- `theme-` — Theme management
- `update-` — Update components

**Examples**:
- `omarchy-cmd-missing` / `omarchy-cmd-present` — Check for commands
- `omarchy-pkg-missing` / `omarchy-pkg-present` — Check for packages
- `omarchy-pkg-add` — Install packages (handles pacman + AUR)
- `omarchy-hw-asus-rog` — Detect ASUS ROG hardware
- `omarchy-refresh-hyprland` — Copy default Hyprland config
- `omarchy-restart-waybar` — Restart waybar
- `omarchy-toggle-idle` — Toggle idle handling

**Why it's cool**: Discoverable via `omarchy-<TAB>`. Self-documenting.

**NixOS portability**: **EASY** — Generate via Nix, use `home.packages` + scripts.

---

### 9.2 Hardware Detection System ⭐⭐
**What it does**: Detect hardware and return exit codes for use in conditionals.

**Commands**:
- `omarchy-hw-asus-rog` — ASUS ROG laptop
- `omarchy-hw-dell-xps-oled` — Dell XPS with OLED
- `omarchy-hw-framework16` — Framework 16
- `omarchy-hw-intel` — Intel CPU
- `omarchy-hw-intel-ptl` — Intel Panther Lake
- `omarchy-hw-surface` — Microsoft Surface
- `omarchy-hw-vulkan` — Vulkan support

**Usage**:
```bash
if omarchy-hw-asus-rog; then
  # ASUS ROG-specific config
fi
```

**Why it's cool**: Hardware-specific configs without hardcoding.

**NixOS portability**: **MEDIUM** — Use `nixpkgs.stdenv.hostPlatform` + hardware detection modules.

---

### 9.3 Migration System ⭐⭐
**What it does**: Run breaking-change migrations on update.

**Command**: `omarchy-dev-add-migration --no-edit`

**Migration format**:
```bash
echo "Disable fingerprint in hyprlock if fingerprint auth is not configured"

if omarchy-cmd-missing fprintd-list || ! fprintd-list "$USER" 2>/dev/null | grep -q "finger"; then
  sed -i 's/fingerprint:enabled = .*/fingerprint:enabled = false/' ~/.config/hypr/hyprlock.conf
fi
```

**Why it's cool**: Handles config changes gracefully across updates.

**NixOS portability**: **MEDIUM** — Use activation scripts + version tracking.

---

## 10. MENU SYSTEM

### 10.1 Interactive Menu via Walker ⭐⭐
**What it does**: Builds interactive menus using Walker's dmenu mode.

**Command**: `omarchy-menu` (launches main menu)

**Implementation**:
```bash
menu() {
  local prompt="$1"
  local options="$2"
  local extra="$3"
  local preselect="$4"

  read -r -a args <<<"$extra"

  if [[ -n $preselect ]]; then
    local index
    index=$(echo -e "$options" | grep -nxF "$preselect" | cut -d: -f1)
    if [[ -n $index ]]; then
      args+=("-c" "$index")
    fi
  fi

  echo -e "$options" | omarchy-launch-walker --dmenu --width 295 --minheight 1 --maxheight 630 -p "$prompt…" "${args[@]}" 2>/dev/null
}
```

**Why it's cool**: Reusable menu function. Supports preselection.

**NixOS portability**: **EASY** — Port as script.

---

## 11. SYSTEM INTEGRATION

### 11.1 UWSM Integration ⭐⭐
**What it does**: Uses UWSM (Universal Wayland Session Manager) for app launching.

**Pattern**: `uwsm-app -- <command>`

**Why it's cool**: Ensures apps run in correct Wayland session context. Handles GPU/audio setup.

**NixOS portability**: **MEDIUM** — Requires UWSM package + session setup.

---

### 11.2 XDG Defaults ⭐
**What it does**: Respects XDG defaults for terminal, browser, file manager.

**Commands**:
- `xdg-terminal-exec` — Open terminal in current directory
- `xdg-terminal-exec --dir="$(omarchy-cmd-terminal-cwd)"` — Terminal in CWD

**Why it's cool**: Portable across different terminal/browser choices.

**NixOS portability**: **EASY** — Use `xdg.mimeApps` module.

---

## SUMMARY TABLE: Portability & Difficulty

| Feature | Category | Difficulty | Notes |
|---------|----------|-----------|-------|
| Layered config system | Hyprland | EASY | Use `home.file` + sourcing |
| Window popping | Hyprland | EASY | Port as script |
| Dynamic toggles | Hyprland | MEDIUM | Requires runtime state dir |
| Keybinding system | Hyprland | EASY | Generate via Nix |
| Monitor scaling cycle | Hyprland | EASY | One-liner script |
| Internal monitor toggle | Hyprland | EASY | Script wrapper |
| Transparency toggle | Hyprland | EASY | One-liner script |
| Workspace layout toggle | Hyprland | EASY | Script wrapper |
| Modular waybar config | Waybar | EASY | Use `programs.waybar` |
| Workspace persistence | Waybar | EASY | Config setting |
| Walker configuration | Launcher | EASY | Use `programs.walker` |
| Walker launcher script | Launcher | EASY | Port as script |
| Multi-theme support | Theming | MEDIUM | Requires theme system |
| Atomic theme switching | Theming | HARD | Better to use Stylix |
| Template system | Theming | EASY | Use Nix interpolation |
| Smart app launching | Apps | EASY | Port as scripts |
| Web app installer | Apps | EASY | Generate `.desktop` files |
| Default app bindings | Apps | EASY | Set via home-manager |
| Screenshot with editor | Workflows | EASY | Port as script |
| Screen recording | Workflows | MEDIUM | Requires gstreamer |
| File sharing | Workflows | EASY | Port as script |
| Mako config | Notifications | EASY | Use `services.mako` |
| Hypridle config | Idle | EASY | Use `services.hypridle` |
| Hyprlock config | Lockscreen | EASY | Use `programs.hyprlock` |
| Semantic commands | Utilities | EASY | Generate via Nix |
| Hardware detection | Utilities | MEDIUM | Use nixpkgs detection |
| Migration system | System | MEDIUM | Use activation scripts |
| Menu system | UI | EASY | Port as script |
| UWSM integration | System | MEDIUM | Requires UWSM package |
| XDG defaults | System | EASY | Use `xdg.mimeApps` |

---

## TOP 5 PATTERNS WORTH STEALING

1. **Layered Config System** — Separate immutable defaults from user customizations via sourcing. Enables safe updates + user freedom.

2. **Semantic Command Naming** — All utilities follow `omarchy-<prefix>-<action>` pattern. Discoverable, self-documenting.

3. **Smart Application Launching** — `launch-or-focus` prevents duplicate instances. `webapp-install` turns web apps into desktop apps.

4. **Dynamic Toggles** — Store config snippets as files, source them. Toggles persist across reboots without editing configs.

5. **Atomic Theme Switching** — Swap entire theme directory atomically. User customizations overlay official themes. All apps update in sync.

---

## GOTCHAS & CONSIDERATIONS

- **Arch-specific**: Omarchy uses pacman + AUR. NixOS equivalents: `nixpkgs` + `nur`.
- **Systemd-heavy**: Many scripts use `systemd-run --user`. NixOS has `systemd.user.services`.
- **Runtime state**: Toggles + theme switching require `~/.local/state/` directory. NixOS can use `$XDG_STATE_HOME`.
- **Theming complexity**: Omarchy's theme system is Arch-specific. Stylix is the NixOS equivalent.
- **Hardware detection**: Omarchy detects via `/sys/class/dmi/id/`. NixOS has `nixpkgs.stdenv.hostPlatform`.

---

## RECOMMENDED NEXT STEPS

1. **Port semantic command system** — Create `lib/omarchy-commands.nix` to generate all utility scripts.
2. **Implement layered config** — Use `home.file` to generate sourced Hyprland configs.
3. **Add dynamic toggles** — Create systemd user service to manage toggle state.
4. **Port smart launchers** — Create `programs.hyprland.bindings` with `launch-or-focus` helpers.
5. **Extend theme system** — Integrate with Stylix for multi-app theming.

---

**Report generated**: April 17, 2026  
**Omarchy version**: v3.5.1 (dev branch)  
**Repository**: https://github.com/basecamp/omarchy
