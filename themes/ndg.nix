# A stylesheet for ndg (the docs of ~/nixos, modules/docs.nix there) in the website's
# look: ndg's own layout and theme switch stay, its colour and font variables are set
# from the site's palette, corners go square, JetBrains Mono everywhere, the dot grid
# behind the content. The fonts are embedded (ndg copies one stylesheet file).
# Used as `ndg html -s ${legacyPackages.<system>.ndgTheme}`.
{ pkgs, root }:
let
  inherit (pkgs) lib;
  inherit (import ./palette.nix { inherit lib root; }) vars;
  # ndg's variables, in terms of the site's (--bg, --panel, --fg, --muted, --line, --accent)
  ndgVars = ''
    --bg-color: var(--bg); --bg-surface: var(--panel); --bg-surface-2: var(--line);
    --text-color: var(--fg); --text-muted: var(--muted); --heading-color: var(--fg);
    --link-color: var(--accent); --link-hover-color: var(--accent);
    --brand: var(--accent); --brand-hover: var(--accent);
    --focus-ring: color-mix(in srgb, var(--accent) 40%, transparent);
    --border-color: var(--line); --border-strong: var(--muted);
    --table-border-color: var(--line); --code-bg: var(--panel); --code-border: var(--line);
    --header-bg: var(--bg); --header-text: var(--fg); --header-muted: var(--muted);
    --header-border: var(--line);
    --sidebar-bg: var(--bg); --sidebar-hover: var(--panel); --sidebar-active: var(--panel);
    --footer-bg: var(--bg);
    --radius-sm: 0; --radius-md: 0; --radius-lg: 0; --radius-xl: 0;
    --shadow-sm: none; --shadow-md: none; --shadow-lg: none;
    --font-mono: "JetBrains Mono", ui-monospace, Menlo, monospace;
  '';
  # :not(#_) raises the selectors above ndg's own scheme rules, whatever their order.
  cssText = ''
    /* ndg docs in the style of enricocinti.com (themes/ndg.nix there) */
    @font-face { font-family: "JetBrains Mono"; font-weight: 400; font-display: swap;
      src: url("data:font/woff2;base64,@FONT400@") format("woff2"); }
    @font-face { font-family: "JetBrains Mono"; font-weight: 700; font-display: swap;
      src: url("data:font/woff2;base64,@FONT700@") format("woff2"); }

    html:root:not(#_) { ${vars "light"} ${ndgVars} color-scheme: light; }
    @media (prefers-color-scheme: dark) {
      html:root:not([data-theme="light"]):not(#_) { ${vars "dark"} ${ndgVars} color-scheme: dark; }
    }
    html:root[data-theme="dark"]:not(#_) { ${vars "dark"} ${ndgVars} color-scheme: dark; }

    body, input, button, select, textarea {
      font-family: "JetBrains Mono", ui-monospace, Menlo, monospace !important;
      font-variant-ligatures: none;
    }
    body { font-size: 14px; }
    main.content {
      background-image: radial-gradient(var(--line) 1px, transparent 0);
      background-size: 20px 20px;
    }
    header { backdrop-filter: none !important; }
    .site-title, .site-title a {
      font-weight: 700; letter-spacing: .2em; text-transform: uppercase; font-size: 14px;
    }
    main.content h1 { letter-spacing: -.02em; }
    main.content h1::before { content: "# "; color: color-mix(in srgb, var(--accent) 45%, var(--bg)); }
    main.content h2 { padding-bottom: 8px; border-bottom: 1px solid var(--line); }
    .sidebar-section summary, .sidebar h2, .sidebar h3 {
      font-size: 11px; letter-spacing: .16em; text-transform: uppercase; color: var(--muted);
    }
    main.content pre, main.content table { border: 1px solid var(--line); }
  '';
  css = pkgs.writeText "ndg-theme.css" cssText;
in
pkgs.runCommand "ndg-theme.css" { passthru = { inherit cssText; }; } ''
  sed -e "s|@FONT400@|$(base64 -w0 ${root + "/static/fonts/jetbrains-mono-latin-400-normal.woff2"})|" \
      -e "s|@FONT700@|$(base64 -w0 ${root + "/static/fonts/jetbrains-mono-latin-700-normal.woff2"})|" \
      ${css} > $out
''
