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
                type = lib.types.string;
                description = "The full name of the license.";
              };

              short = lib.options.create {
                type = lib.types.string;
                description = "The short name of the license.";
              };
            };

            spdx = lib.options.create {
              type = lib.types.nullish lib.types.string;
              default.value = null;
              description = "The SPDX identifier for the license.";
            };

            url = lib.options.create {
              type = lib.types.nullish lib.types.string;
              description = "The URL for the license.";
            };

            free = lib.options.create {
              type = lib.types.bool;
              default.value = true;
              description = "Whether the license is free.";
            };

            redistributable = lib.options.create {
              type = lib.types.bool;
              default = {
                text = "config.free";
                value = config.free;
              };
              description = "Whether the license is allows redistribution.";
            };
          };
        });
      in
        lib.types.either type (lib.types.list.of type);

      meta = lib.types.submodule {
        options = {
          name = lib.options.create {
            type = lib.types.string;
            description = "The name of the package.";
          };

          description = lib.options.create {
            type = lib.types.nullish lib.types.string;
            default.value = null;
            description = "The description for the package.";
          };

          homepage = lib.options.create {
            type = lib.types.nullish lib.types.string;
            default.value = null;
            description = "The homepage for the package.";
          };

          license = lib.options.create {
            type = lib.types.nullish config.lib.types.license;
            default.value = null;
            description = "The license for the package.";
          };

          free = lib.options.create {
            type = lib.types.bool;
            default.value = true;
            description = "Whether the package is free.";
          };

          insecure = lib.options.create {
            type = lib.types.bool;
            default.value = false;
            description = "Whether the package is insecure.";
          };

          broken = lib.options.create {
            type = lib.types.bool;
            default.value = false;
            description = "Whether the package is broken.";
          };

          main = lib.options.create {
            type = lib.types.nullish lib.types.string;
            default.value = null;
            description = "The main entry point for the package.";
          };

          platforms = lib.options.create {
            type = lib.types.list.of lib.types.string;
            default.value = [];
            description = "The platforms the package supports.";
          };
        };
      };

      builder = lib.types.submodule {
        freeform = lib.types.any;

        options = {
          build = lib.options.create {
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
                  namespace = namespace;

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
                        namespace = namespace;

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
          options = {
            pname = lib.options.create {
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
              type = lib.types.dag.of (
                lib.types.either
                lib.types.string
                (lib.types.function lib.types.string)
              );
              default.value = {};
            };

            env = lib.options.create {
              type = lib.types.attrs.of lib.types.string;
              default.value = {};
            };

            builder = lib.options.create {
              type = lib'.types.builder;
            };

            deps = {
              build = {
                only = lib.options.create {
                  type = lib'.types.dependencies.generic;
                  default.value = {};
                };

                build = lib.options.create {
                  type = lib'.types.dependencies.generic;
                  default.value = {};
                };

                host = lib.options.create {
                  type = lib'.types.dependencies.generic;
                  default.value = {};
                };

                target = lib.options.create {
                  type = lib'.types.dependencies.generic;
                  default.value = {};
                };
              };

              host = {
                only = lib.options.create {
                  type = lib'.types.dependencies.generic;
                  default.value = {};
                };

                host = lib.options.create {
                  type = lib'.types.dependencies.generic;
                  default.value = {};
                };

                target = lib.options.create {
                  type = lib'.types.dependencies.generic;
                  default.value = {};
                };
              };

              target = {
                only = lib.options.create {
                  type = lib'.types.dependencies.generic;
                  default.value = {};
                };

                target = lib.options.create {
                  type = lib'.types.dependencies.generic;
                  default.value = {};
                };
              };
            };

            versions = lib.options.create {
              type = lib.types.attrs.of lib'.types.packages.generic;
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
            name = lib.options.create {
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
              type = lib.types.nullish lib.types.string;
              default.value = null;
            };

            pname = lib.options.create {
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
              type = lib.types.nullish lib.types.version;
              default.value = null;
            };

            meta = lib.options.create {
              type = lib'.types.meta;
              default.value = {
                name = config.pname;
              };
            };

            platform = {
              build = lib.options.create {
                type = lib.types.nullish lib.types.string;
                default.value = null;
              };

              host = lib.options.create {
                type = lib.types.nullish lib.types.string;
                default.value = null;
              };

              target = lib.options.create {
                type = lib.types.nullish lib.types.string;
                default.value = null;
              };
            };

            phases = lib.options.create {
              type = lib.types.dag.of (
                lib.types.either
                lib.types.string
                (lib.types.function lib.types.string)
              );
              default.value = {};
            };

            env = lib.options.create {
              type = lib.types.attrs.of lib.types.string;
              default.value = {};
            };

            builder = lib.options.create {
              type = lib'.types.builder;
            };

            package = lib.options.create {
              type = lib.types.derivation;
            };

            deps = {
              build = {
                only = lib.options.create {
                  type = lib'.types.dependencies.targeted;
                  default.value = {};
                };

                build = lib.options.create {
                  type = lib'.types.dependencies.targeted;
                  default.value = {};
                };

                host = lib.options.create {
                  type = lib'.types.dependencies.targeted;
                  default.value = {};
                };

                target = lib.options.create {
                  type = lib'.types.dependencies.targeted;
                  default.value = {};
                };
              };

              host = {
                only = lib.options.create {
                  type = lib'.types.dependencies.targeted;
                  default.value = {};
                };

                host = lib.options.create {
                  type = lib'.types.dependencies.targeted;
                  default.value = {};
                };

                target = lib.options.create {
                  type = lib'.types.dependencies.targeted;
                  default.value = {};
                };
              };

              target = {
                only = lib.options.create {
                  type = lib'.types.dependencies.targeted;
                  default.value = {};
                };

                target = lib.options.create {
                  type = lib'.types.dependencies.targeted;
                  default.value = {};
                };
              };
            };

            versions = lib.options.create {
              type = lib.types.attrs.of lib'.types.packages.targeted;
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
