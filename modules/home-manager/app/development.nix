{ config, pkgs, lib, ... }: {

  options = {
    development = {
      enable = lib.mkEnableOption "development tools and IDEs";
    };
  };

  config.home-manager.users.${config.user} = lib.mkIf config.development.enable {
    home.packages = with pkgs; [
      # Code Editors & IDEs
      zed            # Modern code editor
      code-cursor    # AI-powered code editor

      # API Development
      postman        # API development platform
      atac           # API testing tool (TUI)

      # Security Testing
      burpsuite      # Web security testing

      # Version Control
      github-desktop # GitHub GUI client
    ];
  };
}
