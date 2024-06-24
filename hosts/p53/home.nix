{
  imports = [
  ];
  nixpkgs.config.allowUnfree = true;

  home = {
    username = "odin";
    homeDirectory = "/home/odin";

    stateVersion = "24.11";
  };
  programs.home-manager.enable = true;

}
