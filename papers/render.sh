#!/usr/bin/env bash
# Render one paper's LaTeX source to the HTML pieces the paper page loads.
#   render.sh <source dir> <output dir>
# The source dir needs main.tex (and its .bib, figures, …). Writes <out>/body.html,
# <out>/toc.html and <out>/abstract.html. make4ht runs TeX itself, so the paper's own
# macros, numbering and citation style come out as in the PDF; paper.cfg and
# paper.mk4 hold the HTML-specific settings. Used by flake.nix; can be run by hand.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
mkdir -p "$2"
src=$(cd "$1" && pwd) out=$(cd "$2" && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cp -r "$src"/. "$work"
cd "$work"
# One-line definitions in the preamble that contain a _ (see paper.cfg), as \renewcommand
sed -n '1,/\\begin{document}/p' main.tex |
  grep -E '^[[:space:]]*\\(newcommand|renewcommand|def)[^%]*_' |
  sed -E 's/\\newcommand/\\renewcommand/' >paper-macros.tex || true
PAPER_OUT=$out make4ht --utf8 --build-file "$here/paper.mk4" --config "$here/paper.cfg" \
  --output-dir "$work/html" main.tex >"$work/make4ht.log" 2>&1 || {
  tail -40 "$work/make4ht.log" >&2
  exit 1
}
