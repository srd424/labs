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
  config.packages.foundation.gcc = {
    versions = {
      "13.2.0" = {
        config,
        meta,
      }: {
        options = {
          src = lib.options.create {
            type = lib.types.derivation;
            description = "Source for the package.";
          };

          cc = {
            src = lib.options.create {
              type = lib.types.derivation;
              description = "The cc source for the package.";
            };
          };

          gmp = {
            src = lib.options.create {
              type = lib.types.derivation;
              description = "The gmp source for the package.";
            };

            version = lib.options.create {
              type = lib.types.string;
              description = "Version of gmp.";
            };
          };

          mpfr = {
            src = lib.options.create {
              type = lib.types.derivation;
              description = "The mpfr source for the package.";
            };

            version = lib.options.create {
              type = lib.types.string;
              description = "Version of mpfr.";
            };
          };

          mpc = {
            src = lib.options.create {
              type = lib.types.derivation;
              description = "The mpc source for the package.";
            };

            version = lib.options.create {
              type = lib.types.string;
              description = "Version of mpc.";
            };
          };

          isl = {
            src = lib.options.create {
              type = lib.types.derivation;
              description = "The isl source for the package.";
            };
            version = lib.options.create {
              type = lib.types.string;
              description = "Version of isl.";
            };
          };
        };

        config = {
          meta = {
            platforms = ["i686-linux"];
          };

          pname = "gcc";
          version = "13.2.0";

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

          phases = let
            host = lib'.systems.withBuildInfo config.platform.host;
          in {
            unpack = lib.dag.entry.before ["patch"] ''
              # Unpack
              tar xf ${config.src}
              tar xf ${config.gmp.src}
              tar xf ${config.mpfr.src}
              tar xf ${config.mpc.src}
              tar xf ${config.isl.src}
              cd gcc-${config.version}

              ln -s ../gmp-${config.gmp.version} gmp
              ln -s ../mpfr-${config.mpfr.version} mpfr
              ln -s ../mpc-${config.mpc.version} mpc
              ln -s ../isl-${config.isl.version} isl
            '';

            patch = lib.dag.entry.between ["configure"] ["unpack"] ''
              # Patch
              # force musl even if host triple is gnu
              sed -i 's|"os/gnu-linux"|"os/generic"|' libstdc++-v3/configure.host
            '';

            configure = lib.dag.entry.between ["build"] ["patch"] ''
              # Configure
              export CC="gcc -Wl,-dynamic-linker -march=${host.gcc.arch or host.system.cpu.arch} -Wl,${foundation.stage1-musl}/lib/libc.so"
              export CXX="g++ -Wl,-dynamic-linker -Wl,${foundation.stage1-musl}/lib/libc.so"
              export CFLAGS_FOR_TARGET="-Wl,-dynamic-linker -Wl,${foundation.stage1-musl}/lib/libc.so"
              export LIBRARY_PATH="${foundation.stage1-musl}/lib"

              bash ./configure \
                --prefix=$out \
                --build=${config.platform.build.triple} \
                --host=${config.platform.host.triple} \
                --target=${config.platform.target.triple} \
                --with-native-system-header-dir=/include \
                --with-sysroot=${foundation.stage1-musl} \
                --enable-languages=c,c++ \
                --disable-bootstrap \
                --disable-libsanitizer \
                --disable-lto \
                --disable-multilib \
                --disable-plugin \
                CFLAGS=-static \
                CXXFLAGS=-static
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

          src = builtins.fetchurl {
            url = "${mirrors.gnu}/gcc/gcc-${config.version}/gcc-${config.version}.tar.xz";
            sha256 = "4nXnZEKmBnNBon8Exca4PYYTFEAEwEE1KIY9xrXHQ9o=";
          };

          gmp = {
            version = "6.3.0";
            src = builtins.fetchurl {
              url = "${mirrors.gnu}/gmp/gmp-${config.gmp.version}.tar.xz";
              sha256 = "o8K4AgG4nmhhb0rTC8Zq7kknw85Q4zkpyoGdXENTiJg=";
            };
          };

          mpfr = {
            version = "4.2.1";
            src = builtins.fetchurl {
              url = "${mirrors.gnu}/mpfr/mpfr-${config.mpfr.version}.tar.xz";
              sha256 = "J3gHNTpnJpeJlpRa8T5Sgp46vXqaW3+yeTiU4Y8fy7I=";
            };
          };

          mpc = {
            version = "1.3.1";
            src = builtins.fetchurl {
              url = "${mirrors.gnu}/mpc/mpc-${config.mpc.version}.tar.gz";
              sha256 = "q2QkkvXPiCt0qgy3MM1BCoHtzb7IlRg86TDnBsHHWbg=";
            };
          };

          isl = {
            version = "0.24";
            src = builtins.fetchurl {
              url = "https://gcc.gnu.org/pub/gcc/infrastructure/isl-${config.isl.version}.tar.bz2";
              sha256 = "/PeN2WVsEOuM+fvV9ZoLawE4YgX+GTSzsoegoYmBRcA=";
            };
          };
        };
      };
    };
  };
}
