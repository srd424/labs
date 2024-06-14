{
  lib ? import ./../lib,
  foundation ? import ./../foundation {system = "i686-linux";},
}: let
  modules = import ./src/modules.nix;

  result = lib.modules.run {
    modules =
      (builtins.attrValues modules)
      ++ [
        ./src/export.nix
        {
          __file__ = ./default.nix;

          # options.foundation = lib.options.create {
          #   type = lib.types.attrs.of lib.types.derivation;
          # };

          # config.foundation = foundation;
          # config.packages.foundation =
          #   builtins.mapAttrs (name: package: {
          #     name = package.name;

          #     inherit package;

          #     meta = package.meta;
          #   })
          #   foundation;
        }
      ];
  };
in
  result.config
# result.config.exported

