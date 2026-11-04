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

        site = pkgs.stdenvNoCC.mkDerivation {
          name = "enricocinti.com";
          src = pkgs.lib.cleanSource ./.;
          nativeBuildInputs = [ pkgs.zola ];
          buildPhase = ''
            ${pkgs.lib.optionalString (cv != null) "cp ${cv}/cv.pdf static/cv.pdf"}
            zola build --output-dir $out
          '';
          dontInstall = true;
        };

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
