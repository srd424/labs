{ lib, config }:
let
  lib' = config.lib;
in
{
  includes = [ ./basic.nix ];

  options = {
    builders = lib.options.create {
      description = "A set of builders that can be used to build packages.";
      type = lib.types.attrs.of lib'.types.builder;
      default.value = { };
    };
  };
}
