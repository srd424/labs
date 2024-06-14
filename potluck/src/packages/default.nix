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

  targeted' = {
    i686-linux =
      getPackages "i686-linux" generic
      // {
        cross = {
          x86_64-linux = getPackages "x86_64-linux" generic;
        };
      };
  };

  targeted = lib.attrs.generate lib'.systems.doubles.all (system:
    getPackages system generic
    // {
      cross = lib.attrs.generate doubles (
        host: getPackages host generic
      );
    });
in {
  includes = [
    # ./aux/foundation.nix
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
      generic = {
        example = {
          x = {
            meta.platforms = ["i686-linux" "x86_64-linux"];
            version = "1.0.0";

            builder.build = package:
              derivation {
                name = package.name;
                builder = "/bin/sh";
                system = package.platform.build;
              };

            phases = {
              build = package: ''
                make --build ${package.platform.build} --host ${package.platform.host}
              '';

              install = lib.dag.entry.after ["build"] ''
                make install DESTDIR=$out
              '';
            };
          };
        };
      };

      inherit targeted;
    };
  };
}
