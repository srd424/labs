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
  config.packages.foundation.glibc = {
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

          pname = "gcc";
          version = "2.38";

          src = builtins.fetchurl {
            url = "${mirrors.gnu}/libc/glibc-${config.version}.tar.xz";
            sha256 = "+4KZiZiyspllRnvBtp0VLpwwfSzzAcnq+0VVt3DvP9I=";
          };

          builder = builders.basic;

          env = {
            PATH = let
              gcc =
                if config.platform.build.triple == config.platform.host.triple
                # If we're on the same system then we can use the existing GCC instance.
                then foundation.stage2-gcc
                # Otherwise we are going to need a cross-compiler.
                else
                  (meta.extend (args: {
                    config = {
                      platform = {
                        build = config.platform.build.triple;
                        host = config.platform.build.triple;
                        target = lib.modules.override.force config.platform.host.triple;
                      };
                    };
                  }))
                  .config
                  .package;
            in
              lib.paths.bin [
                foundation.stage2-gcc
                foundation.stage2-binutils
                foundation.stage2-gnumake
                foundation.stage2-gnused
                foundation.stage2-gnugrep
                foundation.stage2-gawk
                foundation.stage2-diffutils
                foundation.stage2-findutils
                foundation.stage2-gnutar
                foundation.stage2-gzip
                foundation.stage2-bzip2
                foundation.stage1-xz
              ];
          };

          phases = {
            unpack = lib.dag.entry.before ["patch"] ''
              tar xf ${config.src}
              cd glibc-${config.version}
            '';

            configure = lib.dag.entry.between ["build"] ["patch"] ''
              mkdir build
              cd build
              # libstdc++.so is built against musl and fails to link
              export CXX=false
              bash ../configure \
                --prefix=$out \
                --build=${config.platform.build.triple} \
                --host=${config.platform.host.triple} \
                --with-headers=${foundation.stage1-linux-headers}/include
            '';

            build = lib.dag.entry.between ["install"] ["configure"] ''
              # Build
              make -j $NIX_BUILD_CORES
            '';

            install = lib.dag.entry.after ["build"] ''
              # Install
              make -j $NIX_BUILD_CORES install-strip
            '';
          };
        };
      };
    };
  };
}
