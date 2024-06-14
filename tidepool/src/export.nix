# This file handles creating all of the exports for this project and is not
# exported itself.
{
  lib,
  config,
}: let
  lib' = config.lib;
in {
  config = {
    exports = {
      lib = config.lib;
      modules = import ./modules.nix;

      packages = {
        example = lib'.packages.export "example.x";
      };
    };
  };
}
