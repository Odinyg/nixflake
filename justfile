default:
  @just --list

#add .nix to git -- used as pre-step in rebuild --
rebuild-pre: 
  git add *.nix

#Rebuild nixos and switch
rebuild: rebuild-pre
  sudo nixos-rebuild --flake .#$HOST switch

#Rebuild nixos boot
boot: rebuild-pre
  sudo nixos-rebuild --flake .#$HOST boot

#Update nixos flake
update:
  nix flake update

# See diffrence from lock file
diff:
  git diff ':!flake.lock'
#Take out trash older then 30 days
gc:
  sudo nix-collect-garbage --delete-older-than 30d
