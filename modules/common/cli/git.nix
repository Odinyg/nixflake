{ config, lib, ... }: {

  options = {
    git = {
      enable = lib.mkEnableOption {
        description = "Enable several git";
        default = false;
      }; 
    };
  };
  config.home-manager.users.${config.user} = lib.mkIf config.git.enable {


  programs.git = {
    enable = true;
    userName = "Odin";
    userEmail = "git@pytt.io";
    extraConfig = {
      core.editor = "nvim";
    };
  };

  programs.lazygit = {
    enable = true;
    settings.gui = {
      # showFileTree = false;

      theme = {
        activeBorderColor = ["blue" "bold"];
        selectedLineBgColor = ["white"];
      };
    };
  };

  home.shellAliases = {
    g = "git";
    lg = "lazygit";

    # add
    ga = "git add";
    gaa = "git add *";

    # commit
    gc = "git commit";
    gcm = "git commit -m";
    gca = "git commit -am";

    # pull/push
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
    gt = "git ls-tree -r master --name-only";
    gb = "git branch";
    gbl = "git branch --list";
    gm = "git merge";
    gf = "git fetch";
  };
  };

}
