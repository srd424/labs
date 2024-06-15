{
  lib,
  lib',
  config,
}: {
  config = {
    lib.packages = {
      dependencies = {
        getPackages = dependencies: let
          available =
            builtins.filter
            (dependency: !(builtins.isNull dependency))
            (builtins.attrValues dependencies);
        in
          builtins.map (dependency: dependency.package) available;
      };

      getLatest = alias: let
        versions = builtins.attrNames alias.versions;
        sorted = builtins.sort (builtins.compareVersions) versions;
      in
        builtins.head sorted;

      build = package: system: cross: let
        resolved =
          if package ? versions
          then package.versions.${config.preferences.packages.version} or (lib'.packages.getLatest package)
          else package;

        buildDependencies = builtins.mapAttrs (name: dep: lib'.packages.build dep system cross);

        result = resolved.extend ({config}: {
          config = {
            platform = {
              build = system;
              host = cross;
              target = cross;
            };

            deps = {
              build = {
                only = buildDependencies resolved.deps.build.only;
                build = buildDependencies resolved.deps.build.build;
                host = buildDependencies resolved.deps.build.host;
                target = buildDependencies resolved.deps.build.target;
              };
              host = {
                only = buildDependencies resolved.deps.host.only;
                host = buildDependencies resolved.deps.host.host;
                target = buildDependencies resolved.deps.host.target;
              };
              target = {
                only = buildDependencies resolved.deps.target.only;
                target = buildDependencies resolved.deps.target.target;
              };
            };

            package = config.builder.build config;
          };
        });
      in
        result.config;
    };
  };
}
