{
  lib,
  lib',
  config,
}: {
  config = {
    lib.types = {
      license = let
        type = lib.types.submodule ({config}: {
          options = {
            name = {
              full = lib.options.create {
                description = "The full name of the license.";
                type = lib.types.string;
              };

              short = lib.options.create {
                description = "The short name of the license.";
                type = lib.types.string;
              };
            };

            spdx = lib.options.create {
              description = "The SPDX identifier for the license.";
              type = lib.types.nullish lib.types.string;
              default.value = null;
            };

            url = lib.options.create {
              description = "The URL for the license.";
              type = lib.types.nullish lib.types.string;
            };

            free = lib.options.create {
              description = "Whether the license is free.";
              type = lib.types.bool;
              default.value = true;
            };

            redistributable = lib.options.create {
              description = "Whether the license is allows redistribution.";
              type = lib.types.bool;
              default = {
                text = "config.free";
                value = config.free;
              };
            };
          };
        });
      in
        lib.types.either type (lib.types.list.of type);

      builder = lib.types.submodule {
        freeform = lib.types.any;

        options = {
          build = lib.options.create {
            description = "The build function which takes a package definition and creates a derivation.";
            type = lib.types.function lib.types.derivation;
          };
        };
      };

      packages = lib.types.attrs.of (lib'.types.alias);

      alias = lib.types.attrs.of (lib.types.submodule {
        options = {
          versions = lib.options.create {
            description = "All available package versions.";
            type = lib.types.attrs.of lib'.types.package;
          };
        };
      });

      dependencies = lib.types.attrs.of (lib.types.nullish (lib.types.either lib'.types.alias lib'.types.package));

      package = lib.types.submodule ({
        config,
        meta,
      }: {
        options = {
          extend = lib.options.create {
            description = "Extend the package's submodules with additional configuration.";
            type = lib.types.function lib.types.raw;
            default.value = value: let
              result = meta.extend {
                modules =
                  if builtins.isAttrs value
                  then [{config = value;}]
                  else lib.lists.from.any value;
              };
            in
              result.config;
          };

          name = lib.options.create {
            description = "The name of the package.";
            type = lib.types.string;
            default = {
              text = "\${config.pname}-\${config.version}";
              value =
                if config.pname != null && config.version != null
                then "${config.pname}-${config.version}"
                else "";
            };
          };

          pname = lib.options.create {
            description = "The program name for the package";
            type = lib.types.nullish lib.types.string;
            default.value = null;
          };

          version = lib.options.create {
            description = "The version for the package.";
            type = lib.types.nullish lib.types.version;
            default.value = null;
          };

          meta = {
            description = lib.options.create {
              description = "The description for the package.";
              type = lib.types.nullish lib.types.string;
              default.value = null;
            };

            homepage = lib.options.create {
              description = "The homepage for the package.";
              type = lib.types.nullish lib.types.string;
              default.value = null;
            };

            license = lib.options.create {
              description = "The license for the package.";
              type = lib.types.nullish lib'.types.license;
              default.value = null;
            };

            free = lib.options.create {
              description = "Whether the package is free.";
              type = lib.types.bool;
              default.value = true;
            };

            insecure = lib.options.create {
              description = "Whether the package is insecure.";
              type = lib.types.bool;
              default.value = false;
            };

            broken = lib.options.create {
              description = "Whether the package is broken.";
              type = lib.types.bool;
              default.value = false;
            };

            main = lib.options.create {
              description = "The main entry point for the package.";
              type = lib.types.nullish lib.types.string;
              default.value = null;
            };

            platforms = lib.options.create {
              description = "The platforms the package supports.";
              type = lib.types.list.of lib.types.string;
              default.value = [];
            };
          };

          platform = {
            build = lib.options.create {
              description = "The build platform for the package.";
              type = lib.types.string;
              default.value = "x86_64-linux";
              apply = raw: let
                system = lib'.systems.from.string raw;
                x = lib'.systems.withBuildInfo raw;
              in
                x;
            };

            host = lib.options.create {
              description = "The host platform for the package.";
              type = lib.types.string;
              default.value = "x86_64-linux";
              # apply = raw: let
              #   system = lib'.systems.from.string raw;
              # in {
              #   inherit raw system;

              #   double = lib'.systems.into.double system;
              #   triple = lib'.systems.into.triple system;
              # };
              apply = raw: let
                system = lib'.systems.from.string raw;
                x = lib'.systems.withBuildInfo raw;
              in
                x;
            };

            target = lib.options.create {
              description = "The target platform for the package.";
              type = lib.types.string;
              default.value = "x86_64-linux";
              # apply = raw: let
              #   system = lib'.systems.from.string raw;
              # in {
              #   inherit raw system;

              #   double = lib'.systems.into.double system;
              #   triple = lib'.systems.into.triple system;
              # };
              apply = raw: let
                system = lib'.systems.from.string raw;
                x = lib'.systems.withBuildInfo raw;
              in
                x;
            };
          };

          phases = lib.options.create {
            description = "The phases for the package.";
            type = lib.types.dag.of (
              lib.types.either
              lib.types.string
              (lib.types.function lib.types.string)
            );
            default.value = {};
          };

          env = lib.options.create {
            description = "The environment for the package.";
            type = lib.types.attrs.of lib.types.string;
            default.value = {};
          };

          builder = lib.options.create {
            description = "The builder for the package.";
            type = lib'.types.builder;
          };

          deps = {
            build = {
              only = lib.options.create {
                description = "Dependencies which are only used in the build environment.";
                type = lib'.types.dependencies;
                default.value = {};
              };

              build = lib.options.create {
                description = "Dependencies which are created in the build environment and are executed in the build environment.";
                type = lib'.types.dependencies;
                default.value = {};
              };

              host = lib.options.create {
                description = "Dependencies which are created in the build environment and are executed in the host environment.";
                type = lib'.types.dependencies;
                default.value = {};
              };

              target = lib.options.create {
                description = "Dependencies which are created in the build environment and are executed in the target environment.";
                type = lib'.types.dependencies;
                default.value = {};
              };
            };

            host = {
              only = lib.options.create {
                description = "Dependencies which are only used in the host environment.";
                type = lib'.types.dependencies;
                default.value = {};
              };

              host = lib.options.create {
                description = "Dependencies which are executed in the host environment.";
                type = lib'.types.dependencies;
                default.value = {};
              };

              target = lib.options.create {
                description = "Dependencies which are executed in the host environment which produces code for the target environment.";
                type = lib'.types.dependencies;
                default.value = {};
              };
            };

            target = {
              only = lib.options.create {
                description = "Dependencies which are only used in the target environment.";
                type = lib'.types.dependencies;
                default.value = {};
              };

              target = lib.options.create {
                description = "Dependencies which are executed in the target environment.";
                type = lib'.types.dependencies;
                default.value = {};
              };
            };
          };

          package = lib.options.create {
            description = "The built derivation.";
            type = lib.types.derivation;
            default.value = config.builder.build config;
          };
        };
      });
    };
  };
}
