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
    in
    {
      packages = forAllSystems (pkgs: rec {
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

        # baseUrl = null uses config.toml's base_url (the real domain).
        mkSite = baseUrl: pkgs.stdenvNoCC.mkDerivation {
          name = "enricocinti.com";
          src = pkgs.lib.cleanSource ./.;
          nativeBuildInputs = [ pkgs.zola ];
          buildPhase = ''
            # zola's load_data builds a TLS client even for local files; the Linux sandbox has no CA store.
            export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
            cp ${cv}/cv.pdf static/cv.pdf
            zola build ${pkgs.lib.optionalString (baseUrl != null) "--base-url ${baseUrl}"} --output-dir $out
          '';
          dontInstall = true;
        };

        site = mkSite null;
        # Prototype on the default GitHub Pages URL, while the real domain
        # still points at Google Sites.
        preview = mkSite "https://cintienrico-prog.github.io/enricocinti.com";

        default = site;
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
