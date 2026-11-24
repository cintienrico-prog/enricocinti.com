#!/usr/bin/env bash
# Fallback renderer (pandoc) for a paper make4ht cannot handle: same interface and
# output as render.sh, but pandoc parses the LaTeX itself instead of running TeX.
#   render-pandoc.sh <source dir> <output dir>
# The source dir needs main.tex; every .bib file next to it is used for citations.
# Writes <out>/body.html (sections, footnotes, references), <out>/toc.html and
# <out>/abstract.html. Used by flake.nix; can be run by hand to test a paper.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
mkdir -p "$2"
src=$(cd "$1" && pwd) out=$(cd "$2" && pwd)
tpl=$(mktemp -d)
trap 'rm -rf "$tpl"' EXIT
printf '%s\n' '$body$' >"$tpl/body.html"
printf '%s\n' '$table-of-contents$' >"$tpl/toc.html"
printf '%s\n' '$abstract$' >"$tpl/abstract.html"

bibs=()
for b in "$src"/*.bib; do [[ -e $b ]] && bibs+=(--bibliography "$b"); done

common=(
  --from latex --to html5
  --mathml                      # equations as MathML: drawn by the browser, no JavaScript
  --section-divs --number-sections
  --lua-filter "$here/math.lua"       # {\cal A} → \mathcal{A}: old font switches in maths
  --lua-filter "$here/equations.lua"  # number labelled equations, resolve \eqref
  --citeproc "${bibs[@]}"
  --metadata link-citations=true
  --metadata reference-section-title=References
  --resource-path "$src"
)
cd "$src"
pandoc main.tex "${common[@]}" --template "$tpl/body.html" -o "$out/body.html"
# \section → h2 and so on: the page title is the only h1. (pandoc's own
# --shift-heading-level-by would renumber the sections 0.1, 0.2, …)
sed -E 's/<(\/?)h5/<\1h6/g; s/<(\/?)h4/<\1h5/g; s/<(\/?)h3/<\1h4/g; s/<(\/?)h2/<\1h3/g; s/<(\/?)h1/<\1h2/g' "$out/body.html" >"$tpl/b" && mv "$tpl/b" "$out/body.html"
pandoc main.tex "${common[@]}" --toc --toc-depth=2 --template "$tpl/toc.html" -o "$out/toc.html"
pandoc main.tex "${common[@]}" --template "$tpl/abstract.html" -o "$out/abstract.html"
