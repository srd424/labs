{
  lib,
  config,
}: let
  cfg = config.builders.basic;

  lib' = config.lib;

  inherit (config) foundation;
in {
  config.builders = {
    basic = {
      executable = "${foundation.stage2-bash}/bin/bash";

      build = package: let
        phases = package.phases;
        sorted = lib.dag.sort.topographic phases;

        script =
          lib.strings.concatMapSep "\n" (
            entry:
              if builtins.isFunction entry.value
              then entry.value package
              else entry.value
          )
          sorted.result;

        system = package.platform.build.double;
      in
        builtins.derivation (
          package.env
          // {
            inherit (package) name;
            inherit script system;

            passAsFile = ["script"];

            SHELL = cfg.executable;

            PATH = let
              bins = lib.paths.bin (
                (lib'.packages.dependencies.getPackages package.deps.build.host)
                ++ [
                  foundation.stage2-bash
                  foundation.stage2-coreutils
                ]
              );
            in
              builtins.concatStringsSep ":" ([bins] ++ (lib.lists.when (package.env ? PATH) [package.env.PATH]));

            builder = cfg.executable;

            args = [
              "-e"
              (builtins.toFile "bash-builder.sh" ''
                export CONFIG_SHELL=$SHELL

                # Normalize the NIX_BUILD_CORES variable. The value might be 0, which
                # means that we're supposed to try and auto-detect the number of
                # available CPU cores at run-time.
                NIX_BUILD_CORES="''${NIX_BUILD_CORES:-1}"
                if ((NIX_BUILD_CORES <= 0)); then
                  guess=$(nproc 2>/dev/null || true)
                  ((NIX_BUILD_CORES = guess <= 0 ? 1 : guess))
                fi
                export NIX_BUILD_CORES

                bash -eux $scriptPath
              '')
            ];
          }
        );
    };
  };
}
