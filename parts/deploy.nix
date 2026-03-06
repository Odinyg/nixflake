{
  inputs,
  ...
}:
let
  inherit (inputs) nixpkgs nixos-hardware;
  lib = import ./lib.nix { inherit inputs; };

  mkColmenaHost =
    {
      hostPath,
      user,
      targetHost,
      stateVersion ? "25.05",
      extraModules ? [ ],
    }:
    { ... }:
    {
      deployment = {
        targetHost = targetHost;
        targetUser = user;
        allowLocalDeployment = true;
      };
      imports = lib.hostModules {
        inherit hostPath user stateVersion extraModules;
      };
    };
in
{
  flake.colmena = {
    meta = {
      nixpkgs = import nixpkgs { system = "x86_64-linux"; };
      specialArgs = {
        inherit inputs;
        inherit (lib) pkgs-unstable;
      };
    };

    laptop = mkColmenaHost {
      hostPath = ../hosts/laptop;
      user = "none";
      targetHost = "laptop";
    };

    VNPC-21 = mkColmenaHost {
      hostPath = ../hosts/vnpc-21;
      user = "odin";
      targetHost = "vnpc-21";
      extraModules = [ nixos-hardware.nixosModules.lenovo-thinkpad-p53 ];
    };

    station = mkColmenaHost {
      hostPath = ../hosts/station;
      user = "none";
      targetHost = "station";
    };
  };
}
