inputs:
let
  system = "x86_64-linux";
  myModules = (builtins.attrValues inputs.my-modules.nixosModules.x86_64-linux);
  homeManagerModule = inputs.home-manager.nixosModules.home-manager;

  additionalModules = myModules ++ [ homeManagerModule ];
in
{
  la = myModules;
  laptop = inputs.nixpkgs.lib.nixosSystem {
    inherit system;
    specialArgs = { inherit inputs; };
    modules = [ (import ./laptop) ];
  };

}
