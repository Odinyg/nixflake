{pkgs, ...}: {
  programs.thunar = {
    enable = true;
    plugins = with pkgs.xfce; [
      thunar-archive-plugin
      thunar-volman
      thunar-media-tags-plugin
    ];
  };
  services = {
    gvfs.enable = true;
    udisks2.enable = true; 
    tumbler.enable = true;
    # devmon.enable = true; # automount
  };
}

