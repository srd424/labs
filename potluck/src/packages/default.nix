{
  lib,
  config,
}: let
  lib' = config.lib;

  doubles = lib'.systems.doubles.all;

  generic = config.packages.generic;

  targeted = {
    i686-linux = generic;
  };
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
            version = "1.0.0";
            builder.build = package:
              derivation {
                name = package.name;
                builder = "/bin/sh";
                system = package.platform.build;
              };
            phases = {
              build = ''
                make
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
