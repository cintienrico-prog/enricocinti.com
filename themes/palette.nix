# The site's palette (config.toml [extra].palette, data/palettes.toml) for the
# other pages styled like the site: the git pages (stagit.nix) and the docs
# (ndg.nix). `vars "dark"` gives the CSS custom properties of one scheme.
{ lib, root }:
let
  config = builtins.fromTOML (builtins.readFile (root + "/config.toml"));
  palettes = builtins.fromTOML (builtins.readFile (root + "/data/palettes.toml"));
  pal = palettes.${config.extra.palette};
in
{
  inherit pal;
  vars = scheme: lib.concatStrings (lib.mapAttrsToList (k: v: "--${k}:${v};") pal.${scheme});
}
