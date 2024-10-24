{ ... }:
{
  imports =
    [
    ];
  nixpkgs.config.allowUnfree = true;

  home = {
    username = "none";
    homeDirectory = "/home/none";
    stateVersion = "24.11";
  };
  programs.home-manager.enable = true;
}
