{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.greetd;
in
{
  options = {
    greetd = {
      enable = lib.mkEnableOption "greetd";
    };
  };
  config = lib.mkIf cfg.enable {
    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --time-format '%I:%M %p | %a • %h | %F' --cmd Hyprland";
          user = "greeter";
        };
      };
    };

    environment.systemPackages = with pkgs; [ greetd.tuigreet ];

  };
}
