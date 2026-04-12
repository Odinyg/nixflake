{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.work;
in
{
  imports = [
    ./communication.nix
    ./development.nix
    ./productivity.nix
    ./remote-access.nix
  ];

  options = {
    work = {
      enable = lib.mkEnableOption "all work-related modules";
    };
  };

  config = lib.mkIf cfg.enable {
    # Enable all submodules when work.enable is true
    work.communication.enable = lib.mkDefault true;
    work.development.enable = lib.mkDefault true;
    work.productivity.enable = lib.mkDefault true;
    work.remoteAccess.enable = lib.mkDefault true;
  };
}
