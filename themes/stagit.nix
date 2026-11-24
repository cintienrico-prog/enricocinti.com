# A stylesheet (and logo, favicon, font) for stagit's pages, in the website's look:
# the palette set in config.toml, both schemes, JetBrains Mono, the dot grid.
# ~/nixos (modules/git.nix) copies `legacyPackages.<system>.stagitTheme` next to
# the pages, where stagit's own style.css, logo.png and favicon.png would go.
{ pkgs, root }:
let
  inherit (pkgs) lib;
  inherit (import ./palette.nix { inherit lib root; }) vars;
  cssText = ''
    /* stagit pages in the style of enricocinti.com (themes/stagit.nix there) */
    @font-face { font-family: "JetBrains Mono"; font-weight: 400; font-display: swap;
      src: url("fonts/jetbrains-mono-latin-400-normal.woff2") format("woff2"); }
    @font-face { font-family: "JetBrains Mono"; font-weight: 700; font-display: swap;
      src: url("fonts/jetbrains-mono-latin-700-normal.woff2") format("woff2"); }
    :root { ${vars "dark"} color-scheme: dark; }
    @media (prefers-color-scheme: light) { :root { ${vars "light"} color-scheme: light; } }
    :root { --surface: color-mix(in srgb, var(--fg) 5%, var(--panel)); }

    body {
      margin: 0 auto; padding: 32px; max-width: 1120px;
      background: var(--bg) radial-gradient(var(--line) 1px, transparent 0) 0 0 / 20px 20px;
      color: var(--fg);
      font: 14px/1.6 "JetBrains Mono", ui-monospace, Menlo, monospace;
      font-variant-ligatures: none;
    }
    a { color: var(--accent); text-decoration: none; }
    a:hover { text-decoration: underline; text-underline-offset: 3px; }
    a:target { background: color-mix(in srgb, var(--accent) 20%, transparent); }
    h1, h2, h3, h4, h5, h6 { font-size: 1em; margin: 0; }
    h1 { font-size: 22px; font-weight: 700; letter-spacing: -.01em; }
    img { border: 0; vertical-align: middle; }
    hr { border: 0; border-top: 1px solid var(--line); height: 0; margin: 16px 0; }
    .desc { color: var(--muted); }
    .url { color: var(--muted); }

    /* the header table: logo, name, description, clone URL, then the menu line */
    body > table:first-child td { padding: 2px 8px 2px 0; }
    body > table:first-child tr:last-child td:last-child { padding-top: 10px; }
    body > table:first-child tr:last-child td:last-child a { margin-right: .3ch; }

    #content { margin-top: 8px; }
    #content > table, #index {
      border: 1px solid var(--line); background: var(--panel);
      border-collapse: collapse; width: 100%;
    }
    table td { padding: 6px 12px; }
    table thead td {
      font-weight: 400; color: var(--muted); font-size: 12px;
      letter-spacing: .16em; text-transform: uppercase;
      border-bottom: 1px solid var(--line);
    }
    #content table td { vertical-align: top; white-space: nowrap; }
    #index tr td:nth-child(2), #tags tr td:nth-child(3),
    #branches tr td:nth-child(3), #log tr td:nth-child(2) { white-space: normal; }
    #branches tr:hover td, #tags tr:hover td, #index tr:hover td,
    #log tr:hover td, #files tr:hover td { background: var(--surface); }
    td.num { text-align: right; color: var(--muted); }
    #log tbody td:first-child, #index tbody td:last-child { color: var(--c-year, var(--accent)); }

    pre {
      font: inherit; padding: 16px; overflow-x: auto;
      border: 1px solid var(--line); background: var(--panel);
    }
    #blob a { color: var(--muted); }
    #blob a:hover { color: var(--accent); text-decoration: none; }
    a.d, a.h, a.i, a.line { text-decoration: none; }
    pre a.h { color: var(--c-note, var(--accent)); }
    .A, span.i, pre a.i { color: var(--accent); }
    .D, span.d, pre a.d { color: #e5484d; }
    pre a.h:hover, pre a.i:hover, pre a.d:hover { text-decoration: none; }
  '';
  css = pkgs.writeText "style.css" cssText;
in
pkgs.runCommand "stagit-theme" { nativeBuildInputs = [ pkgs.librsvg ]; passthru = { inherit cssText; }; } ''
  mkdir -p $out/fonts
  cp ${css} $out/style.css
  cp ${root + "/static/fonts"}/jetbrains-mono-latin-{400,700}-normal.woff2 $out/fonts/
  rsvg-convert -w 32 -h 32 ${root + "/static/img/mark.svg"} -o $out/logo.png
  rsvg-convert -w 32 -h 32 ${root + "/static/img/mark.svg"} -o $out/favicon.png
''
