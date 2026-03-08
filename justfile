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
#Take out trash older then 30 days
gc:
  sudo nix-collect-garbage --delete-older-than 14d

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

# --- Homelab deployment ---

# Deploy to all homelab servers
deploy-all: rebuild-pre
  nix shell nixpkgs#colmena -c colmena apply --on byob,psychosocial,pulse,sugar

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
