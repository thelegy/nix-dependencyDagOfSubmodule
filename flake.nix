{

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    {

      lib =
        let
          extraLib = lib: {
            types.dependencyDagOfSubmodule = import ./dependencyDagOfSubmodule.nix lib;
          };
        in
        extraLib nixpkgs.lib
        // {
          bake = lib: lib.recursiveUpdate lib (extraLib lib);
        };

      checks.x86_64-linux.evaluationCheck = nixpkgs.legacyPackages.x86_64-linux.callPackage ./checks.nix {
        lib = self.lib.bake nixpkgs.lib;
      };

    };

}
