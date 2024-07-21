{ pkgs, lib, ... }:
{
  programs.eza.enable = true;

  home.shellAliases = {
    ls = "${pkgs.eza}/bin/eza";
    l = "${pkgs.eza}/bin/eza -lhgF";
    ll = "${pkgs.eza}/bin/eza -alhgF";
  };
}
