{ config, lib, ... }:
{

  options = {
    zellij = {
      enable = lib.mkEnableOption "Zellij terminal multiplexer";
    };
  };
  config.home-manager.users.${config.user} = lib.mkIf config.zellij.enable {

    programs.zellij = {
      enable = true;
      enableZshIntegration = true;
    };

    # Zellij config in KDL format (programs.zellij.settings generates KDLV1 but zellij uses KDL)
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
