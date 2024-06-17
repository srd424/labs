{
  lib,
  lib',
  config,
  options,
}: let
  inherit
    (config)
    mirrors
    builders
    # These are the upstream foundational packages exported from the Aux Foundation project.
    
    foundation
    ;
in {
  config.packages.foundation.linux-headers = {
    versions = {
      "latest" = {
        config,
        meta,
      }: {
        options = {
          src = lib.options.create {
            type = lib.types.derivation;
            description = "Source for the package.";
          };
        };

        config = {
          meta = {
            platforms = ["i686-linux"];
          };

          pname = "linux-headers";
          version = "6.5.6";

          builder = builders.basic;

          env = {
            PATH = lib.paths.bin [
              foundation.stage2-gcc
              foundation.stage1-musl
              foundation.stage2-binutils
              foundation.stage2-gnumake
              foundation.stage2-gnupatch
              foundation.stage2-gnused
              foundation.stage2-gnugrep
              foundation.stage2-gawk
              foundation.stage2-diffutils
              foundation.stage2-findutils
              foundation.stage2-gnutar
              foundation.stage1-xz
            ];
          };

          phases = {
            unpack = lib.dag.entry.before ["patch"] ''
              tar xf ${config.src}
              cd linux-${config.version}
            '';

            patch =
              lib.dag.entry.between ["configure"] ["unpack"] ''
              '';

            configure =
              lib.dag.entry.between ["build"] ["patch"] ''
              '';

            build = lib.dag.entry.between ["install"] ["configure"] ''
              make -j $NIX_BUILD_CORES CC=musl-gcc HOSTCC=musl-gcc ARCH=${config.platform.host.linux.arch} headers
            '';

            install = lib.dag.entry.after ["build"] ''
              find usr/include -name '.*' -exec rm {} +
              mkdir -p $out
              cp -rv usr/include $out/
            '';
          };

          src = builtins.fetchurl {
            url = "https://cdn.kernel.org/pub/linux/kernel/v${lib.versions.major config.version}.x/linux-${config.version}.tar.xz";
            sha256 = "eONtQhRUcFHCTfIUD0zglCjWxRWtmnGziyjoCUqV0vY=";
          };
        };
      };
    };
  };
}
