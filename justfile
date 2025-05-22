HOST := `hostname`

default:
  @just --list

#add .nix to git -- used as pre-step in rebuild --
rebuild-pre:
  git add *.nix
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
