{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.fonts;
in
{
  options = {
    fonts = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable fonts";
      };
    };
  };
  config = lib.mkIf cfg.enable {
    fonts = {
      packages = with pkgs; [
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-color-emoji
        font-awesome
        source-han-sans
        source-han-serif
        nerd-fonts.droid-sans-mono
        nerd-fonts.jetbrains-mono
        # Microsoft fonts (Calibri, Times New Roman, Arial)
        corefonts
        vista-fonts
      ];
    };
  };
}
