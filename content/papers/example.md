+++
title = "Rendering Test: A Paper as a Web Page"
template = "paper.html"
# A test page for the paper template (papers/example). As a draft it is left out of
# the published site; `nix run` shows it at /papers/example/.
draft = true

[extra]
# Rendered sources: the name in `papers` in flake.nix.
paper = "example"
# Citation key in data/publications.bib, for authors, venue, year/status and DOI.
# The test paper has none, so the fields below stand in.
bib = ""
authors = "Enrico Cinti"
venue = "Test document"
status = "example"
# A PDF built from the same source (flake.nix), linked from the page.
pdf = true
+++
