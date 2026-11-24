{
  description = "enricocinti.com — personal academic website";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  # LaTeX CV: Overleaf project MyCV ↔ its repo on the VPS, mirrored to GitHub
  # (see CLAUDE.md). Update with: nix flake update cv-src
  inputs.cv-src = { url = "github:cintienrico-prog/MyCV"; flake = false; };

  outputs = { self, nixpkgs, cv-src }:
    let
      # Papers rendered as pages on the site (papers/README.md): name → directory with
      # main.tex and its .bib files. The name is the folder the page loads
      # (`paper = "…"` in content/papers/<page>.md). A paper kept in its own repo becomes a
      # non-flake input here, like cv-src.
      papers = {
        example = ./papers/example;
      };

      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});

      # Everything that builds the site, per system. Kept out of `packages` so that
      # only derivations end up there (mkSite is a function).
      build = pkgs:
        let
          cv = pkgs.stdenvNoCC.mkDerivation {
            name = "cv";
            src = cv-src;
            nativeBuildInputs = [ (pkgs.texliveMedium.withPackages (ps: with ps; [
              latexmk moderncv biblatex biber datatool
            ])) ];
            buildPhase = ''
              export HOME=$TMPDIR
              latexmk -pdf -interaction=nonstopmode main.tex
            '';
            installPhase = "install -Dm644 main.pdf $out/cv.pdf";
          };

          # The data the CV and the site share lives in MyCV's data/ folder (its README):
          # publications.bib, teaching.csv, supervision.csv. Copied into data/ before zola
          # runs (gitignored here).
          installCvData = ''
            for f in publications.bib teaching.csv supervision.csv; do
              install -m 0644 ${cv-src}/data/$f data/$f
            done
          '';

          # TeX for the papers: make4ht/tex4ht for the HTML, latexmk for the PDF, and
          # beyond scheme-medium the two collections papers draw on most (latexextra:
          # csquotes, authblk, footmisc, …; mathscience: braket, physics, …), plus bbm.
          # A paper needing something else: add it here.
          paperTex = pkgs.texliveMedium.withPackages (ps: with ps; [
            latexmk make4ht tex4ht luaxml biber biblatex bbm bbm-macros
            collection-latexextra collection-mathscience
          ]);
          # One paper: HTML pieces from papers/render.sh (make4ht), and the PDF (latexmk).
          renderPaper = name: src: pkgs.stdenvNoCC.mkDerivation {
            name = "paper-${name}";
            inherit src;
            nativeBuildInputs = [ paperTex ];
            buildPhase = ''
              export HOME=$TMPDIR
              bash ${./papers}/render.sh . html
              latexmk -pdf -interaction=nonstopmode main.tex
            '';
            installPhase = ''
              mkdir -p $out
              cp -r html $out/html
              cp main.pdf $out/paper.pdf
            '';
          };
          renderedPapers = pkgs.linkFarm "papers"
            (pkgs.lib.mapAttrsToList (name: src: { inherit name; path = renderPaper name src; }) papers);
          # Puts each paper's HTML where paper.html loads it, and its PDF under /papers/.
          # Both places are gitignored.
          installPapers = ''
            mkdir -p data/papers static/papers
            for p in ${renderedPapers}/*; do
              n=$(basename "$p")
              rm -rf "data/papers/$n"
              cp -r "$p/html" "data/papers/$n"
              chmod -R u+w "data/papers/$n"
              install -m 0644 "$p/paper.pdf" "static/papers/$n.pdf"
            done
          '';

          # zola's load_data builds a TLS client even for local files; the Linux sandbox has no CA store.
          zolaEnv = "export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";

          # baseUrl = null uses config.toml's base_url (the real domain).
          mkSite = baseUrl: pkgs.stdenvNoCC.mkDerivation {
            name = "enricocinti.com";
            src = pkgs.lib.cleanSource ./.;
            nativeBuildInputs = [ pkgs.zola ];
            buildPhase = ''
              ${zolaEnv}
              cp ${cv}/cv.pdf static/cv.pdf
              ${installCvData}
              ${installPapers}
              zola build ${pkgs.lib.optionalString (baseUrl != null) "--base-url ${baseUrl}"} --output-dir $out
            '';
            dontInstall = true;
          };
        in
        {
          inherit cv zolaEnv mkSite installCvData installPapers paperTex;
          site = mkSite null;
          # Prototype on the default GitHub Pages URL, while the real domain
          # still points at Google Sites.
          preview = mkSite "https://cintienrico-prog.github.io/enricocinti.com";
        };

      # Palette validation, evaluated in Nix: every palette in data/palettes.toml needs
      # dark + light tables with all keys as #rrggbb, and config.toml must name an existing one.
      palettes = builtins.fromTOML (builtins.readFile ./data/palettes.toml);
      configExtra = (builtins.fromTOML (builtins.readFile ./config.toml)).extra;
      requiredKeys = [
        "bg" "panel" "fg" "muted" "line" "accent" "accent-ink"
        "c-title" "c-year" "c-link" "c-prompt" "c-who" "c-note"
      ];
    in
    {
      packages = forAllSystems (pkgs:
        let b = build pkgs; in {
          inherit (b) cv site preview;
          default = b.site;
        });

      # `nix flake check` (also run by CI before deploying):
      #   site      full build: templates, BibTeX parsing, teaching.toml, palette lookup, CV compile
      #   zola-check zola's internal link check, drafts included (external links skipped: no network in the sandbox)
      #   palettes  structure and hex values of every palette; config.toml's palette, scheme and photo_style are valid
      checks = forAllSystems (pkgs:
        let
          b = build pkgs;
          lib = pkgs.lib;
          problems =
            lib.concatLists (lib.mapAttrsToList
              (name: p: lib.concatMap
                (mode:
                  let t = p.${mode} or { }; in
                  map (k: "${name}.${mode}.${k}")
                    (lib.filter (k: !(t ? ${k}) || builtins.match "#[0-9a-fA-F]{6}" (toString t.${k}) == null) requiredKeys))
                [ "dark" "light" ])
              palettes)
            ++ lib.optional (!(palettes ? ${configExtra.palette})) "config.toml: unknown palette \"${configExtra.palette}\""
            ++ lib.optional (!(builtins.elem (configExtra.scheme or "auto") [ "auto" "dark" "light" ])) "config.toml: scheme must be auto, dark or light"
            ++ lib.optional (!(builtins.elem (configExtra.photo_style or "greyscale") [ "greyscale" "duotone" "plain" ])) "config.toml: photo_style must be greyscale, duotone or plain";
        in
        {
          site = b.site;

          zola-check = pkgs.stdenvNoCC.mkDerivation {
            name = "zola-check";
            src = pkgs.lib.cleanSource ./.;
            nativeBuildInputs = [ pkgs.zola ];
            buildPhase = ''
              ${b.zolaEnv}
              cp ${b.cv}/cv.pdf static/cv.pdf
              ${b.installCvData}
              ${b.installPapers}
              zola check --drafts --skip-external-links
            '';
            installPhase = "touch $out";
          };

          palettes = pkgs.runCommand "palettes-check" { } (
            if problems == [ ] then "touch $out"
            else "printf 'invalid palette data:\\n%s\\n' '${lib.concatStringsSep "\n" problems}'; exit 1"
          );
        });

      # mkSite for other flakes: `legacyPackages.<system>.mkSite "<base URL>"`
      # builds the site for another address (the VPS preview in ~/nixos);
      # `mkSite null` is the same as packages.site.
      # stagitTheme: style.css, logo, favicon and font for the git pages on the VPS
      # (stagit/theme.nix), in the site's palette.
      legacyPackages = forAllSystems (pkgs: {
        inherit (build pkgs) mkSite;
        stagitTheme = import ./stagit/theme.nix { inherit pkgs; root = ./.; };
      });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell { packages = [ pkgs.zola (build pkgs).paperTex ]; };
      });

      # `nix run` → live-reloading preview at http://127.0.0.1:1111, drafts included, with
      # the built CV and papers in place (both gitignored) so /cv.pdf and /papers/ work too.
      # Re-run it after changing a paper's source.
      apps = forAllSystems (pkgs: {
        default = {
          type = "app";
          program = toString (pkgs.writeShellScript "serve" ''
            ${(build pkgs).zolaEnv}
            install -m 0644 ${(build pkgs).cv}/cv.pdf static/cv.pdf
            ${(build pkgs).installCvData}
            ${(build pkgs).installPapers}
            exec ${pkgs.zola}/bin/zola serve --drafts
          '');
        };
      });
    };
}
