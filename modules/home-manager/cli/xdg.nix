{
  config,
  lib,
  pkgs,
  ...
}:
{

  options = {
    xdg = {
      enable = lib.mkEnableOption "XDG base directory specification";
    };
  };
  config.home-manager.users.${config.user} = lib.mkIf config.xdg.enable {
    home.packages = [
      pkgs.xdg-utils
      pkgs.xdg-user-dirs
    ];

    xdg = {
      enable = true;

      userDirs.enable = true;

      mimeApps = {
        enable = true;

        defaultApplications =
          let
            browser = [ "zen-beta.desktop" ];
            photo = [ "feh.desktop" ];
            video = [ "vlc.desktop" ];
            office = [ "onlyoffice-desktopeditors.desktop" ];
            audio = [ "vlc.desktop" ];
            archive = [ "xarchiver.desktop" ];
            terminal = [ "kitty.desktop" ];
            fileManager = [ "thunar.desktop" ];
          in
          {
            # File Manager
            "inode/directory" = fileManager;
            # Applications
            "application/pdf" = browser;

            # Text
            "text/html" = browser;
            "text/xml" = browser;
            "image/gif" = photo;
            "image/heif" = photo;
            "image/jpeg" = photo;
            "image/png" = photo;
            "image/webp" = photo;
            "application/octet-stream" = photo; # matplotlib figures

            # Videos
            "video/mp4" = video; # .mp4
            "video/quicktime" = video; # .mov
            "video/x-matroska" = video; # .mkv
            "video/x-ms-wmv" = video; # .wmv
            "x-scheme-handler/http" = browser;
            "x-scheme-handler/https" = browser;
            "x-scheme-handler/discord" = [ "vesktop.desktop" ];
            # Documents
            "application/msword" = office;
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = office;
            "application/vnd.ms-excel" = office;
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = office;
            "application/vnd.ms-powerpoint" = office;
            "application/vnd.openxmlformats-officedocument.presentationml.presentation" = office;
            "application/vnd.oasis.opendocument.text" = office;
            "application/vnd.oasis.opendocument.spreadsheet" = office;
            "application/vnd.oasis.opendocument.presentation" = office;
            "application/zip" = archive;
            "application/x-rar" = archive;
            "application/x-tar" = archive;
            "application/x-7z-compressed" = archive;
            "audio/mpeg" = audio;
            "audio/x-wav" = audio;
            "audio/flac" = audio;
          };
      };
    };
  };
}
