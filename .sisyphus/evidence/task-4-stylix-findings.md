# Task 4 — Stylix in standalone Home Manager (`inputs.stylix.homeModules.stylix`)

## Result
- **Did it work?** **YES**
- Standalone eval succeeded with `inputs.stylix.homeModules.stylix` added to `parts/home-manager-standalone.nix` module list, and Stylix options set directly in `hosts/station-arch/home.nix`.

## Test Setup (temporary, reverted)
- Added to `parts/home-manager-standalone.nix` modules list:
  - `inputs.stylix.homeModules.stylix`
- Set in `hosts/station-arch/home.nix`:
  - `stylix.enable = true;`
  - `stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/nord.yaml";`
  - `stylix.image = ../../modules/home-manager/desktop/hyprland/wallpaper/wallpaper.png;`
  - `stylix.polarity = "dark";`
  - `stylix.opacity.terminal = 0.85;`
  - `stylix.autoEnable = true;`
  - `stylix.cursor.package = pkgs.bibata-cursors;`
  - `stylix.cursor.name = "Bibata-Modern-Ice";`
  - `stylix.cursor.size = 18;`

## Eval Evidence
- Command:
  - `nix eval .#homeConfigurations."none@station".activationPackage.drvPath 2>&1`
- Output:
  - `warning: Git tree '/home/none/nixflake' is dirty`
  - `"/nix/store/js4nwqvsqgwcsi61l1f7lrpg9lx6y82v-home-manager-generation.drv"`

## What Works in Standalone HM
- Works with `inputs.stylix.homeModules.stylix`:
  - `stylix.enable`
  - `stylix.base16Scheme`
  - `stylix.image`
  - `stylix.polarity`
  - `stylix.opacity.terminal`
  - `stylix.autoEnable`
  - `stylix.cursor.{package,name,size}`

## What Did Not Work / NixOS-only Notes
- No failure occurred for tested Stylix options.
- From current `modules/nixos/styling.nix`, these are **NixOS-layer concerns** (not standalone HM module options by themselves):
  - `styling.*` option namespace (wrapper options defined by local NixOS module)
  - `home-manager.users.${config.user}.gtk.iconTheme` assignment in NixOS module context
- **Fonts note:** current `modules/nixos/styling.nix` does not set `stylix.fonts.*`; no standalone fonts-specific Stylix option was exercised in this test.

## Recommendation for Task 16
- Use standalone HM Stylix by importing `inputs.stylix.homeModules.stylix` in `parts/home-manager-standalone.nix`.
- Configure `stylix.*` directly in `hosts/station-arch/home.nix` (or split into HM-only theming module) rather than relying on NixOS `styling.*` wrapper options.
- Keep wallpaper path anchored to repo file path as used here.

## Revert Confirmation
- Temporary Stylix additions were removed:
  - `parts/home-manager-standalone.nix` restored to original modules list (no Stylix module)
  - `hosts/station-arch/home.nix` restored to minimal skeleton state
