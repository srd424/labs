{
  lib,
  config,
}: let
  lib' = config.lib;
in {
  config = {
    lib.packages = {
      get = path: let
        resolved =
          if builtins.isList path
          then path
          else lib.strings.split "." path;

        package = lib.attrs.selectOrThrow resolved config.packages.generic;
      in
        assert lib.errors.trace (builtins.length resolved > 1) "Packages must have a namespace specified.";
          package
          // {
            namespace = lib.modules.override 99 (builtins.head resolved);
          };

      export = path: system: let
        resolved =
          if builtins.isList path
          then path
          else lib.strings.split "." path;

        package = lib'.packages.get resolved;
        targeted = lib.attrs.selectOrThrow resolved config.packages.targeted.${system};
      in
        if builtins.elem system package.meta.platforms
        then targeted.package
        else null;
    };
  };
}
