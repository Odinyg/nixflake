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
    work.communication = {
      enable = lib.mkEnableOption {
        description = "Enable work communication tools (Zoom, AnyDesk)";
        default = false;
      };
    };
  };

  config = lib.mkIf config.work.communication.enable {
    environment.systemPackages = with pkgs; [
      anydesk
      teams-for-linux
      zoom-us
    ];
  };
}
