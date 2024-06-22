{
  lib,
  lib',
  config,
}:
{
  config = {
    lib.packages = {
      dependencies = {
        getPackages =
          dependencies:
          let
            available = builtins.filter (dependency: !(builtins.isNull dependency)) (
              builtins.attrValues dependencies
            );
          in
          builtins.map (dependency: dependency.package) available;
      };

      getLatest =
        alias:
        let
          versions = builtins.attrNames alias.versions;
          sorted = builtins.sort (lib.versions.gte) versions;
        in
        builtins.head sorted;

      build =
        package: build: host: target:
        let
          resolved =
            if package ? versions then
              package.versions.${config.preferences.packages.version}
                or (package.versions.${lib'.packages.getLatest package})
            else
              package;

          buildDependencies =
            build': host': target':
            builtins.mapAttrs (name: dep: lib'.packages.build dep build' host' target');

          result = resolved.extend (
            { config }:
            {
              config = {
                platform = {
                  build = build;
                  host = host;
                  target = lib.modules.override 150 target;
                };

                deps = {
                  build = {
                    only = buildDependencies build build build resolved.deps.build.only;
                    build = buildDependencies build build target resolved.deps.build.build;
                    host = buildDependencies build host target resolved.deps.build.host;
                    target = buildDependencies build target target resolved.deps.build.target;
                  };
                  host = {
                    only = buildDependencies host host host resolved.deps.host.only;
                    host = buildDependencies host host target resolved.deps.host.host;
                    target = buildDependencies host target target resolved.deps.host.target;
                  };
                  target = {
                    only = buildDependencies target target target resolved.deps.target.only;
                    target = buildDependencies target target target resolved.deps.target.target;
                  };
                };

                package = config.builder.build config;
              };
            }
          );
        in
        result;
    };
  };
}
