# Draft: Hyprland Mutable Override Layer

## Requirements (confirmed)
- User wants to experiment with desktop theming/config without `just rebuild`
- Core settings stay in Nix (consistency, reproducibility)
- Secondary mutable file(s) override Nix-managed settings with first priority
- Workflow: experiment in dotfile → promote to Nix when satisfied

## Current Architecture
- Hyprland: `wayland.windowManager.hyprland.settings` (Nix attrs → generated config)
- Keybindings: `wayland.windowManager.hyprland.settings.bind` (arrays)
- Monitors: `wayland.windowManager.hyprland.extraConfig` (raw text)
- Waybar: `xdg.configFile."waybar".source = ./config/waybar` (static symlink → read-only)
- Rofi: `xdg.configFile."rofi/config.rasi".source = ./config/rofi.rasi` (static symlink → read-only)
- Kitty: `programs.kitty.extraConfig` (Nix-generated)
- Stylix: Auto-applies Nord theme to everything (colors, GTK, QT, cursor)
- Host overrides: laptop/station/vnpc-21 override settings in their host config

## Technical Approach Options
- **Hyprland**: `source = ~/.config/hypr/overrides.conf` at end of generated config — later values win
- **Kitty**: `include overrides.conf` directive in extraConfig
- **Waybar**: Trickier — currently symlinked read-only files
- **Rofi**: Same issue as waybar — symlinked read-only

## Open Questions
- Which apps matter most? (Hyprland only? Or also waybar/rofi/kitty?)
- How granular should overrides be? (one file? per-concern files?)
- Should Stylix-managed theming be overridable too, or just layout/behavior?
