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
      python312Packages.pip
      talosctl
      rke2
      go
      ghostty

      ripgrep-all
      xh
      gitui
      jq

    ];
  };
}
