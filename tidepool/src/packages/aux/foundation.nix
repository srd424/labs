{
  lib,
  lib',
  config,
  options,
}: let
  builders = config.builders;
in {
  config = {
    packages = {
      example = {
        x = {
          versions = {
            "latest" = {config}: {
              config = {
                meta = {
                  platforms = ["i686-linux" "x86_64-linux"];
                };

                pname = "x";
                version = "1.0.0";

                builder = builders.basic;

                phases = {
                  build = ''
                    make --build ${config.platform.build} --host ${config.platform.host}
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
    };
  };
}
