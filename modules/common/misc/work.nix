{ pkgs, config, lib,... }: {

  options = {
    work = {
      enable = lib.mkEnableOption {
        description = "Enable several work";
        default = false;
      }; 
    };
  };
config = lib.mkIf  config.work.enable{

  environment.systemPackages = with pkgs; [
    anydesk
    zoom-us
    remmina
    inetutils
    thunderbird
    ];
  };
}
