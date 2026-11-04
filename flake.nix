{
  description = "enricocinti.com — personal academic website";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  # LaTeX CV, synced from Overleaf (project MyCV) via its GitHub integration.
  # Update with: nix flake update cv-src
  inputs.cv-src = { url = "github:cintienrico-prog/MyCV"; flake = false; };

  outputs = { self, nixpkgs, cv-src }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});

      # Everything that builds the site, per system. Kept out of `packages` so that
      # only derivations end up there (mkSite is a function).
      build = pkgs:
        let
          cv = pkgs.stdenvNoCC.mkDerivation {
            name = "cv";
            src = cv-src;
            nativeBuildInputs = [ (pkgs.texlive.combine { inherit (pkgs.texlive) scheme-medium latexmk moderncv; }) ];
            buildPhase = ''
              export HOME=$TMPDIR
              latexmk -pdf -interaction=nonstopmode main.tex
            '';
            installPhase = "install -Dm644 main.pdf $out/cv.pdf";
          };

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
              zola build ${pkgs.lib.optionalString (baseUrl != null) "--base-url ${baseUrl}"} --output-dir $out
            '';
            dontInstall = true;
          };
        in
        {
          inherit cv zolaEnv;
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
      #   zola-check zola's internal link check (external links skipped: no network in the sandbox)
      #   palettes  structure and hex values of every palette, and that config.toml's palette exists
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
            ++ lib.optional (!(builtins.elem (configExtra.scheme or "auto") [ "auto" "dark" "light" ])) "config.toml: scheme must be auto, dark or light";
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
              zola check --skip-external-links
            '';
            installPhase = "touch $out";
          };

          palettes = pkgs.runCommand "palettes-check" { } (
            if problems == [ ] then "touch $out"
            else "printf 'invalid palette data:\\n%s\\n' '${lib.concatStringsSep "\n" problems}'; exit 1"
          );
        });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell { packages = [ pkgs.zola ]; };
      });

      # `nix run` → live-reloading preview at http://127.0.0.1:1111
      apps = forAllSystems (pkgs: {
        default = {
          type = "app";
          program = toString (pkgs.writeShellScript "serve" "exec ${pkgs.zola}/bin/zola serve");
        };
      });
    };
}
