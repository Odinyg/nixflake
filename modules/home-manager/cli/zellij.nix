{ config, lib, ... }:
{

  options = {
    zellij = {
      enable = lib.mkEnableOption {
        description = "Enable several zellij";
        default = false;
      };
    };
  };
  config.home-manager.users.${config.user} = lib.mkIf config.zellij.enable {

    programs.zellij = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        theme = "nord";
        themes.nord.fg = "#D8DEE9";
        themes.nord.bg = "#2E3440";
        themes.nord.black = "#3B4252";
        themes.nord.red = "#BF616A";
        themes.nord.green = "#A3BE8C";
        themes.nord.yellow = "#EBCB8B";
        themes.nord.blue = "#81A1C1";
        themes.nord.magenta = "#B48EAD";
        themes.nord.cyan = "#88C0D0";
        themes.nord.white = "#E5E9F0";
        themes.nord.orange = "#D08770";
        pane-frames = false;
      };
    };

    # Create a custom config file with the correct KDL syntax
    xdg.configFile."zellij/config.kdl".text = ''
      theme "nord"
      themes {
          nord {
              fg "#D8DEE9"
              bg "#2E3440"
              black "#3B4252"
              red "#BF616A"
              green "#A3BE8C"
              yellow "#EBCB8B"
              blue "#81A1C1"
              magenta "#B48EAD"
              cyan "#88C0D0"
              white "#E5E9F0"
              orange "#D08770"
          }
      }
      pane_frames false
      show_startup_tips false

      keybinds {
          normal {
              bind "Ctrl a" { SwitchToMode "tab"; }
              unbind "Ctrl h"
              unbind "Ctrl l"
          }
          tab {
              bind "Ctrl a" { GoToNextTab; SwitchToMode "normal"; }
          }
      }
    '';
  };
}
