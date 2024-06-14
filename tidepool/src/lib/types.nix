{
  lib,
  config,
}: let
  lib' = config.lib;
in {
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

      meta = lib.types.submodule {
        options = {
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
            type = lib.types.nullish config.lib.types.license;
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
      };

      builder = lib.types.submodule {
        freeform = lib.types.any;

        options = {
          build = lib.options.create {
            description = "The build function which takes a package definition and creates a derivation.";
            type = lib.types.function lib.types.derivation;
          };
        };
      };

      packages = {
        generic = lib.types.attrs.of (lib.types.submodule ({name}: {
          freeform = lib.types.attrs.of (lib.types.submodule [
            lib'.types.package.generic'
          ]);
        }));

        versioned = lib.types.attrs.of (lib.types.submodule ({name}: {
          freeform = lib.types.attrs.of (lib.types.submodule [
            lib'.types.package.versioned'
          ]);
        }));

        # packages.<system>
        targeted = lib.types.attrs.of (lib.types.submodule ({name}: let
          system = name;
        in {
          # packages.<system>.<namespace>
          freeform = lib.types.attrs.of (lib.types.submodule ({name}: let
            namespace = name;
          in {
            # packages.<system>.<namespace>.<name>
            freeform = lib.types.attrs.of (lib.types.submodule [
              lib'.types.package.targeted'
              {
                config = {
                  namespace = lib.modules.override 99 namespace;

                  platform = {
                    build = system;
                    host = lib.modules.overrides.default system;
                    target = lib.modules.overrides.default system;
                  };
                };
              }
            ]);
          }));

          # packages.<system>.<cross>
          options.cross = lib.attrs.generate lib'.systems.doubles.all (cross:
            lib.options.create {
              description = "A cross-compiling package set.";
              default.value = {};
              # packages.<system>.<cross>.<namespace>
              type = lib.types.attrs.of (lib.types.submodule (
                {name}: let
                  namespace = name;
                in {
                  # packages.<system>.<cross>.<namespace>.<name>
                  freeform = lib.types.attrs.of (lib.types.submodule [
                    lib'.types.package.targeted'
                    {
                      config = {
                        namespace = lib.modules.override 99 namespace;

                        platform = {
                          build = system;
                          host = cross;
                          target = lib.modules.overrides.default cross;
                        };
                      };
                    }
                  ]);
                }
              ));
            });
        }));
      };

      dependencies = {
        generic = lib.types.attrs.of (lib.types.nullish lib'.types.package.generic);
        targeted = lib.types.attrs.of (lib.types.nullish lib'.types.package.targeted);
      };

      package = {
        generic = lib.types.submodule lib'.types.package.generic';

        generic' = args @ {
          name ? assert false; null,
          config,
        }: {
          freeform = lib.types.any;

          options = {
            namespace = lib.options.create {
              description = "The namespace for the package.";
              type = lib.types.nullish lib.types.string;
              default.value = null;
            };

            pname = lib.options.create {
              description = "The program name for the package";
              type = lib.types.string;
              default = {
                text = "<name> or \"unknown\"";
                value =
                  if args ? name
                  then args.name
                  else "unknown";
              };
            };

            version = lib.options.create {
              description = "The version for the package.";
              type = lib.types.nullish lib.types.version;
              default.value = null;
            };

            meta = lib.options.create {
              description = "Metadata for the package.";
              type = lib'.types.meta;
              default.value = {
                name = config.pname;
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
                  type = lib'.types.dependencies.generic;
                  default.value = {};
                };

                build = lib.options.create {
                  description = "Dependencies which are created in the build environment and are executed in the build environment.";
                  type = lib'.types.dependencies.generic;
                  default.value = {};
                };

                host = lib.options.create {
                  description = "Dependencies which are created in the build environment and are executed in the host environment.";
                  type = lib'.types.dependencies.generic;
                  default.value = {};
                };

                target = lib.options.create {
                  description = "Dependencies which are created in the build environment and are executed in the target environment.";
                  type = lib'.types.dependencies.generic;
                  default.value = {};
                };
              };

              host = {
                only = lib.options.create {
                  description = "Dependencies which are only used in the host environment.";
                  type = lib'.types.dependencies.generic;
                  default.value = {};
                };

                host = lib.options.create {
                  description = "Dependencies which are executed in the host environment.";
                  type = lib'.types.dependencies.generic;
                  default.value = {};
                };

                target = lib.options.create {
                  description = "Dependencies which are executed in the host environment which produces code for the target environment.";
                  type = lib'.types.dependencies.generic;
                  default.value = {};
                };
              };

              target = {
                only = lib.options.create {
                  description = "Dependencies which are only used in the target environment.";
                  type = lib'.types.dependencies.generic;
                  default.value = {};
                };

                target = lib.options.create {
                  description = "Dependencies which are executed in the target environment.";
                  type = lib'.types.dependencies.generic;
                  default.value = {};
                };
              };
            };

            versions = lib.options.create {
              description = "Available package versions.";
              type = lib.types.attrs.of lib'.types.package.versioned;
              default.value = {};
            };
          };
        };

        versioned = lib.types.submodule lib'.types.package.versioned';

        versioned' = args @ {
          name ? assert false; null,
          config,
        }: {
          freeform = lib.types.any;

          options = {
            namespace = lib.options.create {
              description = "The namespace for the package.";
              type = lib.types.nullish lib.types.string;
              default.value = null;
            };

            pname = lib.options.create {
              description = "The program name for the package";
              type = lib.types.string;
              default = {
                text = "<name> or \"unknown\"";
                value =
                  if args ? name
                  then args.name
                  else "unknown";
              };
            };

            version = lib.options.create {
              description = "The version for the package.";
              type = lib.types.nullish lib.types.version;
              default.value = null;
            };

            meta = lib.options.create {
              type = lib'.types.meta;
              default.value = {
                name = config.pname;
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
                  type = lib'.types.dependencies.generic;
                  default.value = {};
                };

                build = lib.options.create {
                  description = "Dependencies which are created in the build environment and are executed in the build environment.";
                  type = lib'.types.dependencies.generic;
                  default.value = {};
                };

                host = lib.options.create {
                  description = "Dependencies which are created in the build environment and are executed in the host environment.";
                  type = lib'.types.dependencies.generic;
                  default.value = {};
                };

                target = lib.options.create {
                  description = "Dependencies which are created in the build environment and are executed in the target environment.";
                  type = lib'.types.dependencies.generic;
                  default.value = {};
                };
              };

              host = {
                only = lib.options.create {
                  description = "Dependencies which are only used in the host environment.";
                  type = lib'.types.dependencies.generic;
                  default.value = {};
                };

                host = lib.options.create {
                  description = "Dependencies which are executed in the host environment.";
                  type = lib'.types.dependencies.generic;
                  default.value = {};
                };

                target = lib.options.create {
                  description = "Dependencies which are executed in the host environment which produces code for the target environment.";
                  type = lib'.types.dependencies.generic;
                  default.value = {};
                };
              };

              target = {
                only = lib.options.create {
                  description = "Dependencies which are only used in the target environment.";
                  type = lib'.types.dependencies.generic;
                  default.value = {};
                };

                target = lib.options.create {
                  description = "Dependencies which are executed in the target environment.";
                  type = lib'.types.dependencies.generic;
                  default.value = {};
                };
              };
            };

            versions = lib.options.create {
              description = "Available package versions.";
              type = lib.types.attrs.of lib'.types.package.versioned;
              default.value = {};
            };
          };
        };

        targeted = lib.types.submodule lib'.types.package.targeted';

        targeted' = args @ {
          name ? assert false; null,
          config,
        }: {
          options = {
            freeform = lib.types.any;

            name = lib.options.create {
              description = "The name of the package.";
              type = lib.types.string;
              default = {
                text = "\${namespace}-\${pname}-\${version} or \${pname}-\${version}";
                value = let
                  namespace =
                    if config.namespace == null
                    then ""
                    else "${config.namespace}-";
                  version =
                    if config.version == null
                    then ""
                    else "-${config.version}";
                in "${namespace}${config.pname}${version}";
              };
            };

            namespace = lib.options.create {
              description = "The namespace for the package.";
              type = lib.types.nullish lib.types.string;
              default.value = null;
            };

            pname = lib.options.create {
              description = "The program name for the package.";
              type = lib.types.string;
              default = {
                text = "<name> or \"unknown\"";
                value =
                  if args ? name
                  then args.name
                  else "unknown";
              };
            };

            version = lib.options.create {
              description = "The version for the package.";
              type = lib.types.nullish lib.types.version;
              default.value = null;
            };

            meta = lib.options.create {
              description = "Metadata for the package.";
              type = lib'.types.meta;
              default.value = {
                name = config.pname;
              };
            };

            platform = {
              build = lib.options.create {
                description = "The build platform for the package.";
                type = lib.types.nullish lib.types.string;
                default.value = null;
              };

              host = lib.options.create {
                description = "The host platform for the package.";
                type = lib.types.nullish lib.types.string;
                default.value = null;
              };

              target = lib.options.create {
                description = "The target platform for the package.";
                type = lib.types.nullish lib.types.string;
                default.value = null;
              };
            };

            phases = lib.options.create {
              description = "Build phases for the package.";
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

            package = lib.options.create {
              description = "The built derivation.";
              type = lib.types.derivation;
            };

            deps = {
              build = {
                only = lib.options.create {
                  description = "Dependencies which are only used in the build environment.";
                  type = lib'.types.dependencies.targeted;
                  default.value = {};
                };

                build = lib.options.create {
                  description = "Dependencies which are created in the build environment and are executed in the build environment.";
                  type = lib'.types.dependencies.targeted;
                  default.value = {};
                };

                host = lib.options.create {
                  description = "Dependencies which are created in the build environment and are executed in the host environment.";
                  type = lib'.types.dependencies.targeted;
                  default.value = {};
                };

                target = lib.options.create {
                  description = "Dependencies which are created in the build environment and are executed in the target environment.";
                  type = lib'.types.dependencies.targeted;
                  default.value = {};
                };
              };

              host = {
                only = lib.options.create {
                  description = "Dependencies which are only used in the host environment.";
                  type = lib'.types.dependencies.targeted;
                  default.value = {};
                };

                host = lib.options.create {
                  description = "Dependencies which are executed in the host environment.";
                  type = lib'.types.dependencies.targeted;
                  default.value = {};
                };

                target = lib.options.create {
                  description = "Dependencies which are executed in the host environment which produces code for the target environment.";
                  type = lib'.types.dependencies.targeted;
                  default.value = {};
                };
              };

              target = {
                only = lib.options.create {
                  description = "Dependencies which are only used in the target environment.";
                  type = lib'.types.dependencies.targeted;
                  default.value = {};
                };

                target = lib.options.create {
                  description = "Dependencies which are executed in the target environment.";
                  type = lib'.types.dependencies.targeted;
                  default.value = {};
                };
              };
            };

            versions = lib.options.create {
              description = "Available package versions.";
              type = lib.types.attrs.of lib'.types.package.versioned;
              default.value = {};
            };
          };

          config = {
            package = config.builder.build config;
          };
        };
      };
    };
  };
}
