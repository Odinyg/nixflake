{
  pkgs,
  config,
  lib,
  inputs,
  ...
}:
let
  # Create stable packages overlay
  pkgs-stable = import inputs.nixpkgs-stable {
    system = pkgs.system;
    config.allowUnfree = true;
  };
in
{
  options = {
    work.development = {
      enable = lib.mkEnableOption {
        description = "Enable development tools (GCC, Make, DBeaver, etc.)";
        default = false;
      };
    };
  };

  config = lib.mkIf config.work.development.enable {
    environment.systemPackages = with pkgs; [
      gcc
      gnumake
      pkgs-stable.dbeaver-bin
      expect
      rpiboot
      inetutils
    ];
  };
}