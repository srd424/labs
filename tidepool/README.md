# Aux Tidepool

Aux Tidepool is an initial package set built on top of [Aux Foundation](../foundation). Packages
are created and managed using [Aux Lib](../lib)'s module system to allow for highly dynamic and
extensible configuration.

## Usage

Packages can be imported both with and without Nix Flakes. To import them using Nix Flakes,
add this repository as an input.

```nix
inputs.tidepool.url = "https://git.auxolotl.org/auxolotl/labs/archive/main.tar.gz?dir=tidepool";
```

To import this library without using Nix Flakes, you will need to use `fetchTarball` and
import the library entrypoint.

```nix
let
    labs = builtins.fetchTarball {
        url = "https://git.auxolotl.org/auxolotl/labs/archive/main.tar.gz";
        sha256 = "<sha256>";
    };
    tidepool = import "${labs}/tidepool" {};
in
    # ...
```
