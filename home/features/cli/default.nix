{ pkgs, ... }: {
  imports = [
    ./zsh.nix
  ];
    programs.git = {
    enable = true;
    userName = "Odin";
    userEmail = "git@pytt.io";
    };
  home.packages = with pkgs; [
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
