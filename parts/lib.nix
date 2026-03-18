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
    inherit system;
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
    serverCommonModules
    ++ [
      sharedConfig
      hostPath
      { _module.args = { inherit pkgs-unstable; }; }
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
