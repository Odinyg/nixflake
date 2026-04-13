{ config, lib, ... }:
let
  cfg = config.git;
in
{
  options = {
    git = {
      enable = lib.mkEnableOption "Git version control tools and configuration";

      userName = lib.mkOption {
        type = lib.types.str;
        default = "Odin";
        description = "Git user name for commits";
      };

      userEmail = lib.mkOption {
        type = lib.types.str;
        default = "git@pytt.io";
        description = "Git user email for commits";
      };
    };
  };

  config.home-manager.users.${config.user} = lib.mkIf cfg.enable {

    programs = {
      git = {
        enable = true;
        ignores = [
          "docs/rca"
        ];
        settings = {
          user = {
            name = cfg.userName;
            email = cfg.userEmail;
          };
          core.editor = "nvim";
          credential."https://git.pytt.io".helper = "store";
        };
      };
      lazygit = {
        enable = true;
        settings.gui = {
          theme = {
            activeBorderColor = [
              "blue"
              "bold"
            ];
            selectedLineBgColor = [ "white" ];
          };
        };
      };
      gh = {
        enable = true;
        gitCredentialHelper.enable = true;
      };
    };

    home.shellAliases = {
      g = "git";
      lg = "lazygit";
      ga = "git add";
      gaa = "git add *";
      gc = "git commit";
      gcm = "git commit -m";
      gca = "git commit -am";
      gpl = "git pull";
      gps = "git push";
      gs = "git status";
      gd = "git diff";
      gch = "git checkout";
      gnb = "git checkout -b";
      gac = "git add . && git commit";
      grs = "git restore --staged .";
      gre = "git restore";
      gr = "git remote";
      gcl = "git clone";
      gt = "git ls-tree -r HEAD --name-only";
      gb = "git branch";
      gbl = "git branch --list";
      gm = "git merge";
      gf = "git fetch";
    };
  };

}
