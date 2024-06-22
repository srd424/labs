{ lib, config }:
let
in
{
  config = {
    lib.options = {
      package = lib.options.create {
        type = config.lib.types.package;
        description = "A package definition.";
      };
    };
  };
}
