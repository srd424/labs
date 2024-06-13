{
  description = "A set of foundational packages required for bootstrapping a larger package set.";

  inputs = {
    lib = {
#      url = "path:../lib";
# https://github.com/NixOS/nix/issues/3978
       url = "git+https://github.com/srd424/labs?dir=lib";
    };
  };

  outputs = inputs: let
    inherit (inputs.lib) lib;

    modules = import ./src;

    forEachSystem = lib.attrs.generate [
      "i686-linux"
    ];
  in rec {
    extras = let
      result = lib.modules.run {
        modules =
          builtins.attrValues modules;
      };
    in
      result.config.exports.resolved.extras;

    packages = forEachSystem (
      system: let
        result = lib.modules.run {
          modules =
            (builtins.attrValues modules)
            ++ [
              {config.aux.system = system;}
            ];
        };
      in
        result.config.exports.resolved.packages
    );

    hydraJobs = {
      build = packages;
    };

  };
}
