{ lib }:
{
  options.mirrors = {
    gnu = lib.options.create {
      description = "The GNU mirror to use";
      type = lib.types.string;
      default.value = "https://ftp.gnu.org/gnu";
    };
  };
}
