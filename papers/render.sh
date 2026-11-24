#!/usr/bin/env bash
# Render one paper's LaTeX source to the HTML pieces the paper page loads.
#   render.sh <source dir> <output dir>
# The source dir needs main.tex (and its .bib, figures, …). Writes <out>/body.html,
# <out>/toc.html and <out>/abstract.html, plus make4ht.log and latex.log.
# On a copy of the source: prepare.lua rewrites what TeX4ht can't take, then make4ht
# runs TeX itself, with paper.cfg (TeX4ht settings) and paper.mk4 (build steps and
# the HTML clean-up). Used by flake.nix; can be run by hand (nix develop).
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
mkdir -p "$2"
src=$(cd "$1" && pwd) out=$(cd "$2" && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cp -r "$src"/. "$work"
cd "$work"

texlua "$here/prepare.lua" main.tex
status=0
PAPER_OUT=$out make4ht --utf8 --build-file "$here/paper.mk4" --config "$here/paper.cfg" \
  --output-dir "$work/html" main.tex >make4ht.log 2>&1 || status=$?

# The logs, next to the output: make4ht's summary leaves out the context of errors.
cp make4ht.log "$out/make4ht.log"
cp main.log "$out/latex.log" 2>/dev/null || true
if [ "$status" -ne 0 ]; then
  tail -40 make4ht.log >&2
  echo "render.sh: make4ht failed; logs in $out" >&2
  exit 1
fi
