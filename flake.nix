{
  description = "enricocinti.com — personal academic website";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (pkgs: rec {
        # CV built from cv/cv.tex if that file exists. Until then, drop a
        # ready-made static/cv.pdf into the repo instead.
        cv =
          if builtins.pathExists ./cv/cv.tex then
            pkgs.stdenvNoCC.mkDerivation {
              name = "cv";
              src = ./cv;
              nativeBuildInputs = [ (pkgs.texlive.combine { inherit (pkgs.texlive) scheme-medium latexmk; }) ];
              buildPhase = ''
                export HOME=$TMPDIR
                latexmk -pdf -interaction=nonstopmode cv.tex
              '';
              installPhase = "install -Dm644 cv.pdf $out/cv.pdf";
            }
          else null;

        # baseUrl = null uses config.toml's base_url (the real domain).
        mkSite = baseUrl: pkgs.stdenvNoCC.mkDerivation {
          name = "enricocinti.com";
          src = pkgs.lib.cleanSource ./.;
          nativeBuildInputs = [ pkgs.zola ];
          buildPhase = ''
            # zola's load_data builds a TLS client even for local files; the Linux sandbox has no CA store.
            export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
            ${pkgs.lib.optionalString (cv != null) "cp ${cv}/cv.pdf static/cv.pdf"}
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
