# enricocinti.com

Static site built with [Zola](https://www.getzola.org), packaged with a Nix flake,
deployed to GitHub Pages by a GitHub Action.

## Day to day

| I want to…                    | Edit                         |
|-------------------------------|------------------------------|
| add or fix a publication      | `data/publications.bib`      |
| add a course                  | `data/teaching.toml`         |
| change the about / home text  | `content/about.md`, `content/_index.md` |
| change links or the nav       | `config.toml` (`[extra]`)    |
| update the CV                 | replace `static/cv.pdf` (or `cv/cv.tex`, see below) |
| change colours / fonts        | top of `static/style.css`    |

Preview locally with live reload:

```sh
nix run          # serves http://127.0.0.1:1111
# or: nix develop -c zola serve
```

Publish: commit and push to `main`. The Action builds `nix build .#site` and deploys.

Note: the flake only sees files git knows about, so `git add` new files
(e.g. `static/cv.pdf`, a photo) before `nix build`.

## Layout

```
config.toml                 site settings, links, nav
content/*.md                page text
data/publications.bib       publications (rendered by templates/publications.html)
data/teaching.toml          teaching list
templates/                  HTML templates (Tera)
static/                     copied as-is: style.css, js/keys.js, CNAME, cv.pdf, img/
flake.nix                   packages.site, packages.cv, devShell, `nix run` preview
.github/workflows/deploy.yml
```

## CV from LaTeX (optional)

Put your CV source in `cv/cv.tex` (plus any files it needs). The flake then
builds it with `latexmk` and places `cv.pdf` in the site automatically; delete
`static/cv.pdf` once that works. If your CV needs packages outside
`scheme-medium`, add them in `flake.nix`.

## Keyboard shortcuts

`h a p t` jump between pages, `j k` move through lists, Enter opens an abstract.
They are configured by `nav` in `config.toml` and implemented in `static/js/keys.js`.
The site works fine without JavaScript.
