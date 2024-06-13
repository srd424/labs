{
  lib,
  config,
}: let
  lib' = config.lib;

  doubles = lib'.systems.doubles.all;

  generic = builtins.removeAttrs config.packages ["targeted"];
in {
  includes = [
    # ./aux/foundation.nix
  ];

  options = {
    packages = lib.options.create {
      default.value = {};
      type = lib.types.attrs.of (lib.types.submodule {
        freeform = lib.types.any;
      });
    };
  };

  config = {
    packages.targeted.i686-linux = generic;
  };
}
