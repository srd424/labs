{
  lib,
  config,
}: let
  lib' = config.lib;
in {
  config = {
    lib.packages = {
      dependencies = {
        getPackages = path: dependencies: let
          resolved =
            if builtins.isList path
            then path
            else lib.strings.split "." path;

          attrs = lib.attrs.select resolved {} dependencies;
        in
          lib.attrs.mapToList (name: value: value.package) attrs;

        resolve = dependencies: system:
          builtins.mapAttrs
          # Note that this does not correspond to the "host" and "target" platforms, but rather
          # where the code is used and where it is intended to end up.
          (
            host: platforms:
              builtins.mapAttrs
              (
                target: deps:
                  builtins.mapAttrs
                  (
                    name: dependency:
                      assert lib.errors.trace (dependency.namespace != null) "Namespace unknown for dependency `${name}`."; let
                        targeted = lib'.packages.export [dependency.namespace name] system;
                      in
                        if targeted == null
                        then builtins.throw "Dependency `${dependency.namespace}.${name}` does not support system `${system}`."
                        else targeted
                  )
                  deps
              )
              platforms
          )
          dependencies;
      };

      ## Get a package from the package set by its path. The path can be either
      ## a string or a list of strings that is used to access `config.packages.generic`.
      ##
      ## @type String | List String -> Package
      get = path: let
        resolved =
          if builtins.isList path
          then path
          else lib.strings.split "." path;

        package = lib.attrs.selectOrThrow resolved config.packages.generic;
      in
        assert lib.errors.trace (builtins.length resolved > 1) "Cannot get package without a namespace.";
          package
          // {
            namespace = lib.modules.override 99 (builtins.head resolved);
          };

      ## Export a package by its path. Use this function with the `config.exports.packages.*`
      ## options.
      ##
      ## @type String | List String -> String -> Package
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
