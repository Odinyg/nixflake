default:
  @just --list

#add .nix to git -- used as pre-step in rebuild --
rebuild-pre: 
  git add *.nix

#Rebuild nixos and switch
rebuild: rebuild-pre
  scripts/flake-rebuild.sh

#Update nixos flake
update:
  nix flake update

# See diffrence from lock file
diff:
  git diff ':!flake.lock'
