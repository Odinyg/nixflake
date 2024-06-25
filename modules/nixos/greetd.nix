{ lib,pkgs,config,... }: {
  options = {
    greetd = {
      enable = lib.mkEnableOption {
        description = "Enable greetd";
        default = false;
      }; 
    };
  };
config = lib.mkIf  config.greetd.enable{
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --time-format '%I:%M %p | %a • %h | %F' --cmd Hyprland";
        user = "greeter";
      };
    };
  };

  environment.systemPackages = with pkgs; [
    greetd.tuigreet
  ];

};
}
