{
  inputs,
  ...
}:
let
  inherit (inputs) nixpkgs nixpkgs-unstable nixos-hardware;
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
        inherit
          hostPath
          user
          stateVersion
          extraModules
          ;
      };
    };

  mkColmenaServer =
    {
      hostPath,
      targetHost,
      stateVersion ? "25.05",
      extraModules ? [ ],
    }:
    { ... }:
    {
      deployment = {
        targetHost = targetHost;
        targetUser = "odin";
      };
      imports = lib.serverModules {
        inherit hostPath stateVersion extraModules;
      };
    };
in
{
  flake.colmena = {
    meta = {
      nixpkgs = import nixpkgs { system = "x86_64-linux"; };
      nodeNixpkgs = {
        pulse = import nixpkgs-unstable { system = "x86_64-linux"; };
        sugar = import nixpkgs-unstable { system = "x86_64-linux"; };
        byob = import nixpkgs-unstable { system = "x86_64-linux"; };
        psychosocial = import nixpkgs-unstable { system = "x86_64-linux"; };
      };
      specialArgs = {
        inherit inputs;
        inherit (lib) pkgs-unstable;
      };
    };

    # Desktop hosts
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

    # Homelab servers (staging IPs — update to production after cutover)
    pulse = mkColmenaServer {
      hostPath = ../hosts/pulse;
      targetHost = "10.10.30.112";
    };

    sugar = mkColmenaServer {
      hostPath = ../hosts/sugar;
      targetHost = "10.10.30.111";
    };

    byob = mkColmenaServer {
      hostPath = ../hosts/byob;
      targetHost = "10.10.50.110";
    };

    psychosocial = mkColmenaServer {
      hostPath = ../hosts/psychosocial;
      targetHost = "10.10.30.110";
    };
  };
}
