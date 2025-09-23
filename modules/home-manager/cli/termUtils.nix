{
  config,
  pkgs,
  lib,
  ...
}:
{

  options = {
    termUtils = {
      enable = lib.mkEnableOption {
        description = "Enable several TerminalExtra";
        default = false;
      };
    };
  };
  config.home-manager.users.${config.user} = lib.mkIf config.termUtils.enable {
    home.packages = with pkgs; [

      #### ProgramStuff ####
      python3
      talosctl
      sshpass
      bc
      rke2
      go
      btop
      claude-code
      ripgrep-all
      xh
      gitui
      jq

    ];
  };
}
