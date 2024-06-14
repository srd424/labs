{
  config,
  lib,
}: let
  lib' = config.lib;

  cfg = config.exports;
in {
  options = {
    exports.packages = lib.options.create {
      type = lib.types.attrs.of (lib.types.function (lib.types.nullish lib.types.derivation));
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
          packages =
            builtins.mapAttrs
            (name: resolve: resolve system)
            cfg.packages;

          available =
            lib.attrs.filter
            (name: package: package != null)
            packages;
        in
          available
      );

      available =
        lib.attrs.filter
        (system: packages: builtins.length (builtins.attrNames packages) != 0)
        all;
    in
      available;
  };
}
