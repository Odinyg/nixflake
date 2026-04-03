# Shared helpers for flake-parts modules
{ inputs }:
let
  inherit (inputs)
    nixpkgs
    nixpkgs-unstable
    nixvim
    stylix
    home-manager
    sops-nix
    ;

  system = "x86_64-linux";

  pkgs-unstable = import nixpkgs-unstable {
    localSystem = system;
    config.allowUnfree = true;
  };

  # Desktop hosts: full module tree with home-manager, stylix, nixvim
  commonModules = [
    ../modules
    stylix.nixosModules.stylix
    home-manager.nixosModules.home-manager
    sops-nix.nixosModules.sops
  ];

  # Server hosts: lightweight — no home-manager, stylix, or desktop modules
  serverCommonModules = [
    ../modules/server
    sops-nix.nixosModules.sops
    inputs.disko.nixosModules.disko
  ];

  # Applied to every host (desktop + server)
  sharedConfig = {
    networking.enableIPv6 = false;
    services.qemuGuest.enable = true;
  };

  hostModules =
    {
      hostPath,
      user,
      stateVersion ? "25.05",
      extraModules ? [ ],
    }:
    commonModules
    ++ [
      sharedConfig
      hostPath
      { user = user; }
      { nixpkgs.config.allowUnfree = true; }
      { _module.args = { inherit pkgs-unstable; }; }
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          extraSpecialArgs = { inherit inputs pkgs-unstable; };
          users.${user} = {
            imports = [ nixvim.homeModules.nixvim ];
            home = {
              username = user;
              homeDirectory = "/home/${user}";
              stateVersion = stateVersion;
            };
            programs.home-manager.enable = true;
          };
        };
      }
    ]
    ++ extraModules;

  serverModules =
    {
      hostPath,
      stateVersion ? "25.05",
      extraModules ? [ ],
    }:
    let
      hostname = builtins.baseNameOf (toString hostPath);
    in
    serverCommonModules
    ++ [
      sharedConfig
      hostPath
      { _module.args = { inherit pkgs-unstable; }; }
      # Auto-derive sops secrets file from hostname (secrets/<hostname>.yaml)
      { sops.defaultSopsFile = ../secrets + "/${hostname}.yaml"; }
    ]
    ++ extraModules;
in
{
  inherit
    system
    pkgs-unstable
    commonModules
    serverCommonModules
    hostModules
    serverModules
    ;
}
