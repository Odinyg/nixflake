{pkgs, ...}:

{
  home.packages = with pkgs; [
    xfce.exo 
    xfce.thunar
    xfce.thunar-archive-plugin
    xfce.thunar-volman
    xfce.tumbler 
    gvfs
  ];
}
