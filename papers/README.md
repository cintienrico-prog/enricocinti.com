# Papers as pages

A paper's LaTeX source can be rendered as its own page on the site, at
`/papers/<name>/`, with the sections, equations, footnotes and references of the PDF,
a contents column that follows the reader, and a link to the PDF built from the
same source.

How it works:

- `render.sh` turns a source directory (`main.tex` plus its `.bib` files) into three
  HTML pieces: `body.html`, `toc.html`, `abstract.html`, and keeps `make4ht.log` and
  `latex.log` next to them. It runs make4ht (TeX4ht), which typesets the paper with
  TeX itself, so the paper's macros, equation numbers, theorem environments and
  citation style come out as in the PDF. Equations are MathML, drawn by the browser,
  so the page needs no JavaScript for them. It works on a copy of the source; the
  paper and its PDF are never changed.
  - `prepare.lua` (Lua, run with TeX's own `texlua`) rewrites what TeX4ht's MathML
    can't take: environment shorthands (`\beq` → `\begin{eqnarray}`), `eqnarray` →
    `align`, braces for bare macros as accents or scripts (`\hat\cA`, `\sigma^\Psi`),
    and preamble macros containing `_` (re-read once TeX4ht is on, otherwise
    `\GN` → `G_{\tn N}` loses its subscript).
  - `paper.cfg` holds TeX4ht settings for the HTML run only: font sizes and old-style
    switches (`{\cal A}`, `\tiny`, `\mbox` in subscripts) are neutralised.
  - `paper.mk4` is the build file: LaTeX, BibTeX or Biber, LaTeX twice, then a filter
    that drops the title block, turns font classes into `<em>`/`<strong>`, swaps
    MathML `mathvariant` for Unicode letters (browsers ignore it, so `\mathcal{A}`
    would show as a plain A), numbers the headings and splits out the abstract and
    the contents.
- `flake.nix` runs `render.sh` for every entry in `papers`, builds the PDF with
  latexmk, and copies the pieces to `data/papers/<name>/` and the PDF to
  `static/papers/<name>.pdf` before zola runs (both gitignored). LaTeX packages a
  paper needs beyond scheme-medium go in `paperTex` there.
- `templates/paper.html` lays out the page. Title comes from the page file;
  authors, venue, year or status and DOI from the paper's entry in
  `data/publications.bib`.

## Adding a paper

1. Make the source reachable from the flake: a non-flake input pointing at the
   paper's GitHub mirror (like `cv-src`), or a directory in this repo.
   The directory must contain `main.tex`; figures next to it are found too.
2. Add it to `papers` in `flake.nix`: `my-paper = inputs.my-paper-src;`.
3. Add `content/papers/my-paper.md`:

       +++
       title = "The Paper's Title"
       template = "paper.html"
       [extra]
       paper = "my-paper"          # the name in flake.nix
       bib = "cinti-sanchioni-x"   # citation key in data/publications.bib
       pdf = true
       +++

4. In `data/publications.bib`, add `web = {my-paper}` to the entry: the publications
   page then links to the page.
5. `nix run` to look at it (drafts and papers included), then commit.

For published papers, check what the journal allows (usually the accepted
manuscript, not the typeset version; some ask for a notice or a delay).

## Trying a paper before it is public

This repo is public (its GitHub mirror), so an unpublished paper's source should not
be committed to it. To see such a paper on the local preview only:

1. Put its source in `papers/local/<name>/` (`main.tex` and its `.bib`).
2. Add `content/papers/<name>.local.md` like the page file above, with
   `slug = "<name>"`, `draft = true` and, as it has no entry in publications.bib yet,
   `authors`, `status` and `venue` under `[extra]`.
3. Render it and start the preview from the dev shell:

       nix develop -c papers/render.sh papers/local/<name> data/papers/<name>
       nix run

Both places are gitignored, so nothing of it reaches git. Re-run the first command
after changing the source.

## Test page

`example/` is a test document with what papers usually contain. Its page
(`content/papers/example.md`) is a draft: `nix run` shows it at `/papers/example/`,
the published site leaves it out. It contains one of each construct `prepare.lua`
and `paper.cfg` handle; check it after changing them, the template or the CSS.

## Limits

- make4ht needs the paper to compile with TeX4ht; a package it has no support
  for may come out plain or fail. Read `latex.log` in the output folder; a construct
  that compiles in LaTeX but not here usually needs one more rule in `prepare.lua`
  (and a line in the test paper).
- Only one-line preamble macros are re-read for subscripts (see prepare.lua).
- TikZ pictures and other drawings come out as images, not text.
