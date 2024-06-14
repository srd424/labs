{
  lib,
  config,
  options,
}: let
  lib' = config.lib;
in {
  config = {
    packages = {
      generic = {
        example = {
          x = {
            meta.platforms = ["i686-linux" "x86_64-linux"];
            version = "1.0.0";

            builder = config.builders.basic;

            phases = {
              build = package: ''
                make --build ${package.platform.build} --host ${package.platform.host}
              '';

              install = lib.dag.entry.after ["build"] ''
                make install DESTDIR=$out
              '';
            };

            versions = {
              "latest" = config.packages.generic.example.x;
            };
          };
        };
      };
    };
  };
}
