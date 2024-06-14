{
  lib,
  config,
}: let
  lib' = config.lib;

  doubles = lib'.systems.doubles.all;

  generic = config.packages.generic;

  getPackages = system:
    builtins.mapAttrs
    (
      namespace: packages:
        lib.attrs.filter
        (name: package: builtins.elem system package.meta.platforms)
        packages
    );

  targeted = lib.attrs.generate lib'.systems.doubles.all (system:
    getPackages system generic
    // {
      cross = lib.attrs.generate doubles (
        host: getPackages host generic
      );
    });
in {
  includes = [
    ./aux/foundation.nix
  ];

  options = {
    packages = {
      generic = lib.options.create {
        type = lib'.types.packages.generic;
        default.value = {};
      };

      targeted = lib.options.create {
        type = lib'.types.packages.targeted;
      };
    };
  };

  config = {
    packages = {
      inherit targeted;
    };
  };
}
