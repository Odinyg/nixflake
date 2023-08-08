{ pkgs, ... }: {
  imports = [
    ./zsh.nix
    ./git.nix
    ./neovim.nix
  ];
  home.packages = with pkgs; [
  git
  lf
  bc
  ctop
  htop
  ripgrep
  fd
  jq
  nil
  nixfmt
  



 ];
}
