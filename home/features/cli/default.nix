{ pkgs, ... }: {
  imports = [
    ./zsh
    ./git.nix
    ./neovim
  ];
  home.packages = with pkgs; [
  git
  bat
  lf
  bc
  fd
  ctop
  htop
  ripgrep
  fd
  jq
  nil
  nixfmt
  sshfs



 ];
}
