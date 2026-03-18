{ config, pkgs, pkgs-unstable, lib, ... }: {

  options = {
    development = {
      enable = lib.mkEnableOption "development tools and IDEs";
    };
  };

  config.home-manager.users.${config.user} = lib.mkIf config.development.enable {
    home.packages = with pkgs; [
      # Code Editors & IDEs
      pkgs-unstable.code-cursor # AI-powered code editor

      # API Development
      postman        # API development platform
      atac           # API testing tool (TUI)

      # Security Testing
      burpsuite      # Web security testing

      # Database
      pgcli          # PostgreSQL CLI client

      # Version Control
      github-desktop # GitHub GUI client
    ];
  };
}
