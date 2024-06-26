lib: {
  importers = {
    ## Import a JSON file as a Nix value.
    ##
    ## @notest
    ## @type Path -> a
    json = file: builtins.fromJSON (builtins.readFile file);

    ## Import a TOML file as a Nix value.
    ##
    ## @notest
    ## @type Path -> a
    toml = file: builtins.fromTOML (builtins.readFile file);
  };
}
