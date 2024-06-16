# This file handles creating all of the exports for this project and is not
# exported itself.
{
  lib,
  config,
}: let
  lib' = config.lib;
in {
  freeform = lib.types.any;

  config = {
    exports = {
      lib = config.lib;
      modules = import ./modules.nix;

      packages = {
        # foundation-gcc-x86_64 =
        # (config.packages.foundation.gcc.versions."13.2.0".extend (args: {
        #   config = {
        #     platform = {
        #       target = lib.modules.overrides.force "x86_64-linux";
        #     };
        #   };
        # }))
        # .config;
        foundation-gcc = config.packages.foundation.gcc;
        # example-x = config.packages.example.x;
        # cross-example-x-x86_64-linux = config.packages.cross.x86_64-linux.example.x;
      };
    };

    # exported.packages.i686-linux.cross-foundation-gcc-x86_64-linux = config.packages.cross.x86_64-linux.foundation.gcc.package;
  };
}
