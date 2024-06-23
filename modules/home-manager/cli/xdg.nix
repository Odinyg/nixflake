{ config, lib,pkgs, ... }: {

  options = {
    xdg = {
      enable = lib.mkEnableOption {
        description = "Enable xdg";
        default = false;
      }; 
    };
  };
  config.home-manager.users.${config.user} = lib.mkIf config.xdg.enable {


  home.packages = [pkgs.xdg-utils pkgs.xdg-user-dirs];

  xdg = {
    enable = true;

    userDirs = {
      enable = true;

    #  desktop = "${config.home.homeDirectory}/desktop";
    #  documents = "${config.home.homeDirectory}/documents";
    #  download = "${config.home.homeDirectory}/downloads";
    #  music = "${config.home.homeDirectory}/music";
    #  pictures = "${config.home.homeDirectory}/pictures";
    #  publicShare = "${config.home.homeDirectory}/public";
    #  templates = "${config.home.homeDirectory}/templates";
    #  videos = "${config.home.homeDirectory}/videos";
    };

    mimeApps = {
      enable = true;

      defaultApplications = let
        browser = ["chromium.desktop"];
        photo = ["feh.desktop"];
        video = ["vlc.desktop"];
      in {
        # Applications
        "application/pdf" = browser;

        # Text
        "text/html" = browser;
        "text/xml" = browser;

        # Images
        "image/gif" = photo;
        "image/heif" = photo;
        "image/jpeg" = photo;
        "image/png" = photo;
        "image/webp" = photo;
        "application/octet-stream" = photo; # matplotlib figures

        # Videos
        "video/mp4" = "vlc.desktop"; # .mp4
        "video/quicktime" = "vlc.desktop"; # .mov
        "video/x-matroska" = "vlc.desktop"; # .mkv
        "video/x-ms-wmv" = "vlc.desktop"; # .wmv
        "x-scheme-handler/http" = browser;
        "x-scheme-handler/https" = browser;
        "x-scheme-handler/discord" = ["vesktop.desktop"];

      };
    };
  };
  };
}
