{
  lib,
  lib',
  config,
  options,
}:
let
  inherit (config)
    mirrors
    builders
    # These are the upstream foundational packages exported from the Aux Foundation project.

    foundation
    ;
in
{
  config.packages.foundation.binutils = {
    versions = {
      "latest" =
        { config, meta }:
        {
          options = {
            src = lib.options.create {
              type = lib.types.derivation;
              description = "Source for the package.";
            };
          };

          config = {
            meta = {
              platforms = [ "i686-linux" ];
            };

            pname = "binutils";
            version = "2.41";

            builder = builders.basic;

            env = {
              PATH = lib.paths.bin [
                foundation.stage2-gcc
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

            phases =
              let
                patches = [
                  # Make binutils output deterministic by default.
                  ./patches/deterministic.patch
                ];

                configureFlags = [
                  # "CC=musl-gcc"
                  "LDFLAGS=--static"
                  "--prefix=${builtins.placeholder "out"}"
                  "--build=${config.platform.build.triple}"
                  "--host=${config.platform.host.triple}"
                  "--target=${config.platform.target.triple}"

                  "--with-sysroot=/"
                  "--enable-deterministic-archives"
                  # depends on bison
                  "--disable-gprofng"

                  # Turn on --enable-new-dtags by default to make the linker set
                  # RUNPATH instead of RPATH on binaries.  This is important because
                  # RUNPATH can be overridden using LD_LIBRARY_PATH at runtime.
                  "--enable-new-dtags"

                  # By default binutils searches $libdir for libraries. This brings in
                  # libbfd and libopcodes into a default visibility. Drop default lib
                  # path to force users to declare their use of these libraries.
                  "--with-lib-path=:"

                  "--disable-multilib"
                ];
              in
              {
                unpack = lib.dag.entry.before [ "patch" ] ''
                  tar xf ${config.src}
                  cd binutils-${config.version}
                '';

                patch = lib.dag.entry.between [ "configure" ] [ "unpack" ] ''
                  ${lib.strings.concatMapSep "\n" (file: "patch -Np1 -i ${file}") patches}
                '';

                configure = lib.dag.entry.between [ "build" ] [ "patch" ] ''
                  bash ./configure ${builtins.concatStringsSep " " configureFlags}
                '';

                build = lib.dag.entry.between [ "install" ] [ "configure" ] ''
                  make -j $NIX_BUILD_CORES
                '';

                install = lib.dag.entry.after [ "build" ] ''
                  make -j $NIX_BUILD_CORES install-strip
                '';
              };

            src = builtins.fetchurl {
              url = "${mirrors.gnu}/binutils/binutils-${config.version}.tar.xz";
              sha256 = "rppXieI0WeWWBuZxRyPy0//DHAMXQZHvDQFb3wYAdFA=";
            };
          };
        };
    };
  };
}
