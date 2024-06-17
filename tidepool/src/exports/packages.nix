{
  config,
  lib,
}: let
  lib' = config.lib;
in {
  options = {
    exports.packages = lib.options.create {
      type = lib.types.attrs.of (lib'.types.raw);
      default.value = {};
    };

    exported.packages = lib.options.create {
      type = lib.types.attrs.of (lib.types.attrs.of lib.types.derivation);
      default.value = {};
    };
  };

  config = {
    exported.packages = let
      all = lib.attrs.generate lib'.systems.doubles.all (
        system: let
          all =
            builtins.mapAttrs
            (
              name: package: let
                result = lib'.packages.build package system system system;
              in
                result
            )
            config.exports.packages;

          available =
            lib.attrs.filter
            (name: package: builtins.elem system package.meta.platforms)
            all;

          packages =
            builtins.mapAttrs
            (name: package: package.package)
            available;
        in
          packages
      );

      available =
        lib.attrs.filter
        (system: packages: builtins.length (builtins.attrNames packages) != 0)
        all;
    in
      available;
  };
}
