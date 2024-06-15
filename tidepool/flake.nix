{
  inputs = {
    lib = {
#      url = "git+file:../?dir=lib";
# https://github.com/NixOS/nix/issues/3978
       url = "git+https://git.auxolotl.org/auxolotl/labs?dir=lib";

    };
    foundation = {
#      url = "git+file:../?dir=foundation";
      url = "git+https://github.com/srd424/labs&ref=sd-main-2?dir=lib";
      inputs.lib.follows = "lib";
    };
  };

  outputs = inputs: let
    exports = import ./default.nix {
      lib = inputs.lib.lib;
      foundation = inputs.foundation.packages.i686-linux;
    };
  in
    exports;
}
