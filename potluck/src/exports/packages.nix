{
  config,
  lib,
}: let
  lib' = config.lib;
in {
  options = {
    exports.packages = lib.options.create {
      default.value = {};
    };

    exported.packages = lib.options.create {
      default.value = {};
    };
  };

  config = {
    exported.packages = {
      # i686-linux = config.packages.foundation;
    };
  };
}
