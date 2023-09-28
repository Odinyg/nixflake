{pkgs}:
{
  gtk = {
    enable = true;
    theme = {
      package = pkgs.nordic;
      name = "Nordic";
    };   
    iconTheme = {
      name = "Nordzy";
      package = pkgs.nordzy-icon-theme;
    };
    cursorTheme = {
      name = "Nordzy-cursors";
      package = pkgs.nordzy-cursor-theme;
      size = 32;
    };





}
