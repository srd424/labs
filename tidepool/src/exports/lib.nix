{ lib, config }:
let
in
{
  options = {
    exports.lib = lib.options.create { default.value = { }; };

    exported.lib = lib.options.create { default.value = { }; };
  };

  config = {
    exported.lib = config.exports.lib;
  };
}
