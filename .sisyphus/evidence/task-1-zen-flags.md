# T1: Zen Flag Decision

## Zen window class (detected)
CLASS: `zen-beta`

## Thunar window class (detected)  
CLASS: `Thunar`

## --name flag result
OUTCOME: ignored (class unchanged from zen-beta to zen-beta, --name flag did not affect window class)

## Decision for T6 (omo-webapp-install)
EXEC_TEMPLATE: `zen-beta --new-window URL`

**Rationale**: The `--name` flag does not change the window class in Hyprland. Zen always reports class `zen-beta` regardless of the `--name` parameter. Therefore, we cannot use `--name` to create uniquely-identifiable window classes for PWA instances. The fallback is to use `--new-window URL` and rely on window title matching or other heuristics for PWA detection.

## Decision for T5 (omo-launch-or-focus)  
ZEN_CLASS_RE: `zen-beta`
THUNAR_CLASS_RE: `Thunar`

**Rationale**: 
- Zen always reports window class `zen-beta` (confirmed via hyprctl)
- Thunar reports window class `Thunar` (confirmed via hyprctl with DISPLAY=:2)
- These are the exact, literal class strings to match in window manager queries

## Test Evidence
- Zen running: 2 windows with class `zen-beta`
- Thunar launched: 1 window with class `Thunar`
- --name flag test: Launched `zen-beta --name OmoTestPWA --new-window https://example.com`, window class remained `zen-beta` (not `OmoTestPWA`)
