{ ... }:
{
  # Keep the same top-level option names that the NixOS-integrated HM modules expect.
  user = "none";
  hyprland.enable = true;
  git.enable = true;
  mcp.enable = true;

  home.username = "none";
  home.homeDirectory = "/home/none";
  home.stateVersion = "25.05";
  programs.home-manager.enable = true;
}
