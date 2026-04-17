HOST := `hostname`

default:
  @just --list

#add .nix to git -- used as pre-step in rebuild --
rebuild-pre:
  git add . || true
upgrade-pre:
  nix flake update

#Rebuild nixos and switch
rebuild: rebuild-pre
  sudo nixos-rebuild --flake .#{{HOST}} switch

#Rebuild nixos boot
boot: rebuild-pre
  sudo nixos-rebuild --flake .#{{HOST }} boot

#Rebuild verbose
verbose: rebuild-pre
  sudo nixos-rebuild --flake .#{{HOST}} switch --verbose
#Update nixos flake
upgrade: upgrade-pre
  sudo nixos-rebuild --flake .#{{HOST}} switch --upgrade

# See diffrence from lock file
diff:
  git diff ':!flake.lock'
#Take out trash older then 14 days and optimise the store
gc:
  sudo nix-collect-garbage --delete-older-than 14d
  nix-collect-garbage --delete-older-than 14d
  sudo nix-store --optimise

# --- Secrets management ---

# Edit shared desktop secrets (all PCs)
secrets:
  sops secrets/secrets.yaml

# Edit secrets for a specific host
secrets-edit host:
  sops secrets/{{host}}.yaml

# Edit laptop secrets
secrets-laptop:
  sops secrets/laptop.yaml

# Edit station secrets
secrets-station:
  sops secrets/station.yaml

# Edit VNPC-21 secrets
secrets-vnpc-21:
  sops secrets/vnpc-21.yaml

# Edit byob secrets
secrets-byob:
  sops secrets/byob.yaml

# Edit psychosocial secrets
secrets-psychosocial:
  sops secrets/psychosocial.yaml

# Edit pulse secrets
secrets-pulse:
  sops secrets/pulse.yaml

# Edit sugar secrets
secrets-sugar:
  sops secrets/sugar.yaml

# Edit spiders secrets
secrets-spiders:
  sops secrets/spiders.yaml

# --- Theme override management ---

# Reset a mutable theme config to the Nix-managed base version
# Usage: just theme-reset hyprland|waybar|rofi
theme-reset app:
	#!/usr/bin/env bash
	case "{{app}}" in
	hyprland)
		cat > "$HOME/.config/hypr/overrides.conf" <<- 'OVERRIDE'
		# Hyprland mutable overrides — edit freely, no rebuild needed
		# Changes apply on: hyprctl reload
		OVERRIDE
		echo "Reset hyprland overrides to empty"
		;;
	waybar)
		rm -rf "$HOME/.config/waybar"
		cp -a "$HOME/.config/waybar-base" "$HOME/.config/waybar"
		chmod -R u+w "$HOME/.config/waybar"
		echo "Reset waybar config from base"
		;;
	rofi)
		rm -rf "$HOME/.config/rofi"
		mkdir -p "$HOME/.config/rofi"
		cp -a "$HOME/.config/rofi-base/." "$HOME/.config/rofi/"
		chmod -R u+w "$HOME/.config/rofi"
		echo "Reset rofi config from base"
		;;
	*)
		echo "Unknown app: {{app}}. Use: hyprland, waybar, rofi"
		exit 1
		;;
	esac

# Promote mutable theme changes back to the Nix-managed source files
# Usage: just theme-promote hyprland|waybar|rofi
theme-promote app:
	#!/usr/bin/env bash
	REPO_CONFIG="modules/home-manager/desktop/hyprland/config"
	case "{{app}}" in
	hyprland)
		echo "=== Hyprland overrides.conf content ==="
		cat "$HOME/.config/hypr/overrides.conf"
		echo ""
		echo "Hyprland config is Nix attrs — cannot auto-promote."
		echo "Manually move settings you want to keep into:"
		echo "  modules/home-manager/desktop/hyprland/default.nix"
		echo "Then clear overrides: just theme-reset hyprland"
		;;
	waybar)
		cp -a "$HOME/.config/waybar/." "$REPO_CONFIG/waybar/"
		echo "Promoted waybar config to $REPO_CONFIG/waybar/"
		echo "Review changes: git diff $REPO_CONFIG/waybar/"
		;;
	rofi)
		cp "$HOME/.config/rofi/config.rasi" "$REPO_CONFIG/rofi.rasi"
		cp "$HOME/.config/rofi/nord.rasi" "$REPO_CONFIG/rofi-nord.rasi"
		cp "$HOME/.config/rofi/rounded-common.rasi" "$REPO_CONFIG/rounded-common.rasi"
		echo "Promoted rofi config to $REPO_CONFIG/"
		echo "Review changes: git diff $REPO_CONFIG/"
		;;
	*)
		echo "Unknown app: {{app}}. Use: hyprland, waybar, rofi"
		exit 1
		;;
	esac

# --- Homelab deployment ---

# Deploy to all homelab servers
deploy-all: rebuild-pre
  nix shell nixpkgs#colmena -c colmena apply --on byob,psychosocial,pulse,sugar,spiders

# Deploy to a specific server
deploy server: rebuild-pre
  nix shell nixpkgs#colmena -c colmena apply --on {{server}}

# Deploy to byob
deploy-byob: rebuild-pre
  nix shell nixpkgs#colmena -c colmena apply --on byob

# Deploy to psychosocial
deploy-psychosocial: rebuild-pre
  nix shell nixpkgs#colmena -c colmena apply --on psychosocial

# Deploy to pulse
deploy-pulse: rebuild-pre
  nix shell nixpkgs#colmena -c colmena apply --on pulse

# Deploy to sugar
deploy-sugar: rebuild-pre
  nix shell nixpkgs#colmena -c colmena apply --on sugar

# Deploy to spiders
deploy-spiders: rebuild-pre
  nix shell nixpkgs#colmena -c colmena apply --on spiders
