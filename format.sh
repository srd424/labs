#!/usr/bin/env nix-shell
#!nix-shell -i bash -I "nixpkgs=https://github.com/nixos/nixpkgs/archive/nixos-24.05.tar.gz" -p nixfmt-rfc-style

files=$(find . -name "*.nix" -type f)

nixfmt ${1:-"--verify"} ${files}
