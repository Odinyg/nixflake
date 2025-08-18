{
  pkgs,
  config,
  lib,
  ...
}:
{
  imports = [
    ./communication.nix
    ./development.nix
    ./productivity.nix
    ./remote-access.nix
  ];

  options = {
    work = {
      enable = lib.mkEnableOption {
        description = "Enable all work-related modules";
        default = false;
      };
    };
  };

  config = lib.mkIf config.work.enable {
    # Enable all submodules when work.enable is true
    work.communication.enable = lib.mkDefault true;
    work.development.enable = lib.mkDefault true;
    work.productivity.enable = lib.mkDefault true;
    work.remoteAccess.enable = lib.mkDefault true;
  };
}