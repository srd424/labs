{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage1.gnutar;

  platform = config.aux.platform;
  builders = config.aux.foundation.builders;

  stage1 = config.aux.foundation.stages.stage1;
in {
  includes = [
    ./boot.nix
    ./musl.nix
  ];

  options.aux.foundation.stages.stage1.gnutar = {
    package = lib.options.create {
      type = lib.types.package;
      description = "The package to use for gnutar.";
    };

    version = lib.options.create {
      type = lib.types.string;
      description = "Version of the package.";
    };

    src = lib.options.create {
      type = lib.types.package;
      description = "Source for the package.";
    };

    meta = {
      description = lib.options.create {
        type = lib.types.string;
        description = "Description for the package.";
        default.value = "GNU implementation of the `tar' archiver";
      };

      homepage = lib.options.create {
        type = lib.types.string;
        description = "Homepage for the package.";
        default.value = "https://www.gnu.org/software/tar";
      };

      license = lib.options.create {
        # TODO: Add a proper type for licenses.
        type = lib.types.attrs.any;
        description = "License for the package.";
        default.value = lib.licenses.gpl3Plus;
      };

      platforms = lib.options.create {
        type = lib.types.list.of lib.types.string;
        description = "Platforms the package supports.";
        default.value = ["x86_64-linux" "aarch64-linux" "i686-linux"];
      };

      mainProgram = lib.options.create {
        type = lib.types.string;
        description = "The main program of the package.";
        default.value = "tar";
      };
    };
  };

  config = {
    aux.foundation.stages.stage1.gnutar = {
      version = "1.12";

      src = builtins.fetchurl {
        url = "https://ftpmirror.gnu.org/tar/tar-${cfg.version}.tar.gz";
        sha256 = "xsN+iIsTbM76uQPFEUn0t71lnWnUrqISRfYQU6V6pgo=";
      };

      package = builders.bash.boot.build {
        name = "gnutar-${cfg.version}";

        meta = cfg.meta;

        deps.build.host = [
          stage1.tinycc.musl.compiler.package
          stage1.gnumake.boot.package
          stage1.gnused.boot.package
          stage1.gnugrep.package
        ];

        script = ''
          # Unpack
          ungz --file ${cfg.src} --output tar.tar
          untar --file tar.tar
          rm tar.tar
          cd tar-${cfg.version}

          # Configure
          export CC="tcc -B ${stage1.tinycc.musl.libs.package}/lib"
          export LD=tcc
          export ac_cv_sizeof_unsigned_long=4
          export ac_cv_sizeof_long_long=8
          export ac_cv_header_netdb_h=no
          bash ./configure \
            --prefix=$out \
            --build=${platform.build} \
            --host=${platform.host} \
            --disable-nls

          # Build
          make AR="tcc -ar"

          # Install
          make install

        '';
      };
    };
  };
}