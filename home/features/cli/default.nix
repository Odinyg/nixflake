{ pkgs, ... }: {
  imports = [
    ./zsh.nix
    ./git.nix
    ./neovim.nix
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
