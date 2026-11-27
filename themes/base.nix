# The site's look as a plain kit for other pages (the assistant's web app in
# ~/nixos): base.css with the palette's variables for both schemes, the font
# and the dot-grid background; the fonts; the monogram as SVG and as PNG icons
# for an installable web app (192 and 512 px). Pages add their own layout.
{ pkgs, root }:
let
  inherit (pkgs) lib;
  inherit (import ./palette.nix { inherit lib root; }) vars;
  cssText = ''
    /* the look of enricocinti.com (themes/base.nix there) */
    @font-face { font-family: "JetBrains Mono"; font-weight: 400; font-display: swap;
      src: url("fonts/jetbrains-mono-latin-400-normal.woff2") format("woff2"); }
    @font-face { font-family: "JetBrains Mono"; font-weight: 700; font-display: swap;
      src: url("fonts/jetbrains-mono-latin-700-normal.woff2") format("woff2"); }
    :root { ${vars "dark"} color-scheme: dark; }
    @media (prefers-color-scheme: light) { :root { ${vars "light"} color-scheme: light; } }
    html { background: var(--bg); }
    body {
      margin: 0;
      background: var(--bg) radial-gradient(var(--line) 1px, transparent 0) 0 0 / 20px 20px;
      color: var(--fg);
      font: 14px/1.6 "JetBrains Mono", ui-monospace, Menlo, monospace;
      font-variant-ligatures: none;
    }
    a { color: var(--accent); }
    ::selection { background: var(--accent); color: var(--bg); }
  '';
  css = pkgs.writeText "base.css" cssText;
  mark = root + "/static/img/mark.svg";
in
pkgs.runCommand "site-base-theme" { nativeBuildInputs = [ pkgs.librsvg ]; passthru = { inherit cssText; }; } ''
  mkdir -p $out/fonts
  cp ${css} $out/base.css
  cp ${root + "/static/fonts"}/jetbrains-mono-latin-{400,700}-normal.woff2 $out/fonts/
  cp ${mark} $out/icon.svg
  rsvg-convert -w 192 -h 192 ${mark} -o $out/icon-192.png
  rsvg-convert -w 512 -h 512 ${mark} -o $out/icon-512.png
''
