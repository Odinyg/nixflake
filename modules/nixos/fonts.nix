{
  lib,
  pkgs,
  config,
  ...
}:
{
  options = {
    fonts = {
      enable = lib.mkEnableOption {
        description = "Enable fonts";
        default = false;
      };
    };
  };
  config = lib.mkIf config.fonts.enable {
    fonts = {
      packages = with pkgs; [
        noto-fonts
        noto-fonts-cjk
        noto-fonts-emoji
        font-awesome
        source-han-sans
        source-han-sans-japanese
        source-han-serif-japanese
        nerdfonts
      ];
      #    fontconfig = {
      #      enable = true;
      #      defaultFonts = {
      #	      monospace = [ "Meslo LG M Regular Nerd Font Complete Mono" ];
      #	      serif = [ "Noto Serif" "Source Han Serif" ];
      #	      sansSerif = [ "Noto Sans" "Source Han Sans" ];
      #      };
      #    };
    };
  };
}
