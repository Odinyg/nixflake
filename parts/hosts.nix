{
  inputs,
  ...
}:
let
  inherit (inputs) nixpkgs nixos-hardware;
  lib = import ./lib.nix { inherit inputs; };

  mkHost =
    args:
    nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit inputs;
        inherit (lib) pkgs-unstable;
      };
      modules = lib.hostModules args;
    };
in
{
  flake.nixosConfigurations = {
    laptop = mkHost {
      hostPath = ../hosts/laptop;
      user = "none";
    };

    VNPC-21 = mkHost {
      hostPath = ../hosts/vnpc-21;
      user = "odin";
      extraModules = [ nixos-hardware.nixosModules.lenovo-thinkpad-p53 ];
    };

    station = mkHost {
      hostPath = ../hosts/station;
      user = "none";
    };
  };
}
