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
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
in
{
  options = {
    work.development = {
      enable = lib.mkEnableOption "development tools (GCC, Make, DBeaver, etc.)";
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