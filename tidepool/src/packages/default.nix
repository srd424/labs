{
  lib,
  config,
}: let
  lib' = config.lib;

  doubles = lib'.systems.doubles.all;
in {
  includes = [
    ./aux/foundation.nix
  ];

  options = {
    packages = lib.options.create {
      description = "The package set.";
      type = lib'.types.packages;
    };

    preferences.packages = {
      version = lib.options.create {
        description = "The preferred package version when using aliases.";
        type = lib.types.enum ["latest" "stable"];
        default.value = "latest";
      };
    };
  };
}
