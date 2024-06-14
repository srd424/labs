{
  lib,
  config,
  options,
}: let
  lib' = config.lib;
in {
  config = {
    exports.packages.example-x = lib'.packages.export "example.x";

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
    };
  };
}
