{

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    {

      lib =
        let
          extraLib = lib: {
            types.dependencyDagOfSubmodule = import ./default.nix lib;
          };
        in
        extraLib nixpkgs.lib
        // {
          bake = lib: lib.recursiveUpdate lib (extraLib lib);
        };

    };

}
