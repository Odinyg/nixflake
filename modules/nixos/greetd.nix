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
      autoLogin = {
        enable = lib.mkEnableOption "auto-login on boot (safe with disk encryption)";
        user = lib.mkOption {
          type = lib.types.str;
          default = config.user;
          description = "User to auto-login as";
        };
      };
    };
  };
  config = lib.mkIf cfg.enable {
    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.tuigreet}/bin/tuigreet --time --time-format '%I:%M %p | %a • %h | %F' --remember --remember-session --sessions /run/current-system/sw/share/wayland-sessions --xsessions /run/current-system/sw/share/xsessions --cmd Hyprland";
          user = "greeter";
        };
        initial_session = lib.mkIf cfg.autoLogin.enable {
          command = "Hyprland";
          user = cfg.autoLogin.user;
        };
      };
    };

    environment.systemPackages = with pkgs; [ tuigreet ];

  };
}
