{
  lib,
  lib',
  config,
}:
let
  doubles = lib'.systems.doubles.all;

  packages = builtins.removeAttrs config.packages [ "cross" ];
in
{
  includes = [ ./foundation ];

  options = {
    packages = lib.options.create {
      description = "The package set.";
      type = lib.types.submodule {
        freeform = lib.types.attrs.of (lib.types.submodule { freeform = lib'.types.alias; });

        options.cross = lib.attrs.generate doubles (
          system:
          lib.options.create {
            description = "The cross-compiled package set for the ${system} target.";
            type = lib'.types.packages;
            default = { };
          }
        );
      };
    };

    preferences.packages = {
      version = lib.options.create {
        description = "The preferred package version when using aliases.";
        type = lib.types.enum [
          "latest"
          "stable"
        ];
        default.value = "latest";
      };
    };
  };

  config.packages.cross = lib.attrs.generate doubles (
    system:
    builtins.mapAttrs (
      namespace:
      builtins.mapAttrs (
        name: alias:
        let
          setHost =
            package:
            if package != { } then
              (package.extend (
                { config }:
                {
                  config = {
                    platform = {
                      host = lib.modules.overrides.force system;
                      target = lib.modules.overrides.default system;
                    };

                    deps = {
                      build = {
                        only = setHost package.deps.build.only;
                        build = setHost package.deps.build.build;
                        host = setHost package.deps.build.host;
                        target = setHost package.deps.build.target;
                      };
                      host = {
                        only = setHost package.deps.host.only;
                        host = setHost package.deps.host.host;
                        target = setHost package.deps.host.target;
                      };
                      target = {
                        only = setHost package.deps.target.only;
                        target = setHost package.deps.target.target;
                      };
                    };
                  };
                }
              )).config
            else
              package;

          updated = alias // {
            versions = builtins.mapAttrs (version: package: setHost package) alias.versions;
          };
        in
        updated
      )
    ) packages
  );
}
