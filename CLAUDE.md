# CLAUDE.md — enricocinti.com

Context for Claude Code sessions in this repo. Written at the end of the claude.ai
chat where the site was designed (2026-11-04); keep it updated as things change.

## What this is

Enrico Cinti's academic website (philosopher of physics, University of Amsterdam).
It replaces a Google Sites site at www.enricocinti.com. Goals he set:

- off Google Sites, managed as plain files in git;
- built with Nix; free hosting;
- terminal-style design (first references: bashbunni.dev, terminal.shop; since 2026-11-23 restyled after
  poteto.github.io/noodle: near-black `void` palette, JetBrains Mono, faint dot grid, large two-tone headings,
  uppercase section labels over hairlines, framed lists, accent buttons, recent articles as cards). Own touches so it
  is not a clone: `ember` palette (void with an orange accent), a Penrose diagram of Minkowski spacetime beside the
  hero (`templates/partials/penrose.html`, generated), a diamond logo/favicon, and § numbers on section labels;
- keep the old functionality: home, about + CV, publications with abstracts, teaching, contact links.

He is fluent in Nix (NixOS + nix-darwin, hjem, flakes) but new to web hosting.
Explain web/DNS steps; don't explain Nix basics. Treat his corrections as authoritative.
Anything published under his name (About text etc.) must read as his own voice:
draft only when asked, and keep it plain, not LLM-ish.

## Decisions made

- Generator: Zola (single binary, in nixpkgs). Templates are custom, not a Zola theme.
  nixpkgs-unstable ships Zola 0.23.x, which uses Tera 2: no macros/`import` (use `{% component pub.x(...) %}`
  in `templates/partials/macros.html`, called as `{{<pub.x arg={v} />}}`), no `filter`/`slice`/`concat` filters
  (use list comprehensions and `[:n]` slicing), tests take kwargs only. Tera 2 notes:
  https://github.com/Keats/tera2/blob/master/MIGRATION.md
- Data shared with the CV (since 2026-11-24): `publications.bib`, `teaching.csv`, `supervision.csv` live in
  MyCV's `data/` folder (its README); the CV prints them (MyCV `cv-data.tex`: biblatex + datatool) and
  `flake.nix` (`installCvData`) copies them into `data/` here before zola runs (gitignored). Edit them in
  MyCV, push, then `nix flake update cv-src`. Zola loads the .bib with `load_data(format="bibtex")`:
  author lists "First Last and First Last", his own name hidden, the rest shown as "(joint work with …)";
  the BibTeX parser fails on an `@` anywhere outside entries, including comments.
- Paper pages (`papers/README.md`): LaTeX → HTML with make4ht (`papers/render.sh`, `paper.cfg`, `paper.mk4`),
  pandoc as fallback; `templates/paper.html`; unpublished drafts only under gitignored `papers/local/` and
  `content/papers/*.local.md`.
- Git pages on the VPS (stagit) use this site's look: `legacyPackages.<system>.stagitTheme` (`stagit/theme.nix`:
  CSS from the palette in config.toml, `static/img/mark.svg` as logo/favicon, the font); ~/nixos `modules/git.nix`
  copies it next to the pages. A palette change reaches them after `nix flake update website` + deploy there.
- Hosting: GitHub Pages, deployed by `.github/workflows/deploy.yml` (`nix flake check` first, then `nix build .#preview` for now, `.#site` once live,
  `cp -rL result public`, upload-pages-artifact, deploy-pages). Repo must be public. `origin` is a bare repo on the VPS
  (`git@vps.tail8acc21.ts.net:enricocinti.com.git`); GitHub gets every push through the VPS's mirror push
  (`modules/git.nix` in ~/nixos), which triggers the workflow.
- With Actions deploys GitHub ignores `static/CNAME`: the custom domain is set in
  repo Settings → Pages (or `gh api -X PUT repos/cintienrico-prog/enricocinti.com/pages -f cname=www.enricocinti.com`).
- Domain: stays at Namecheap for now (~$14.78/yr renewal). Moving to Cloudflare (~$9/yr) is optional, later.
- VPS (netcup, under test from Nov 2026): `~/nixos` has this flake as input `website` and serves a tailnet-only
  preview at `https://vps.<tailnet>:8444/` with Caddy (`modules/website.nix` there), built with
  `legacyPackages.<system>.mkSite "<preview URL>"`. `mkSite null` = `packages.site`. Keep `mkSite` exported.
  The public site moves to the VPS only if the VPS is kept; until then Google Sites stays live, and GitHub Pages
  is the fallback if the new site has to go public before that.
- Kept as its own flake, not inside his system config. His config (`~/nixos`, jj + git)
  only provides direnv/nix-direnv (`modules/direnv.nix`), `gh` (`modules/shell`), and lists
  this repo in `modules/shell/dotfiles/projects.list` so `projects-sync`/`projects-save` cover it.
  Note: `projects-save` pushes to `main`, which deploys.

## Machines

- enrico-mba: M1 MacBook Air, nix-darwin, user `enricocinti`, rebuild with `rebuild-mba`. Currently the only machine available.
- The Blade (NixOS, user `enrico`) is away for repair; set it up later with `sync`, `rebuild`, `projects-sync`, `direnv allow`.
- Shell is nushell (bash as login shell). GitHub user: `cintienrico-prog`.
- `projects-save [names…] -m "msg"` commits and syncs (fetch, forward/rebase, push); `projects-sync [names…]`
  without committing. This repo is plain git, not jj.

## Prototype phase

The old Google Sites site stays live on www.enricocinti.com; DNS is NOT touched yet. The Actions workflow
builds `.#preview` (same as `.#site` but `--base-url https://cintienrico-prog.github.io/enricocinti.com`) so the
prototype lives at that github.io URL and does not link to the old site. When ready to go live: do steps 7–9,
then switch the workflow to `nix build .#site`.

CV: LaTeX (moderncv, `main.tex`) is edited on Overleaf (project MyCV) or in `~/Projects/MyCV`. Since
2026-11-20 the VPS syncs Overleaf ↔ its repo (`MyCV`, `modules/overleaf-sync.nix` in ~/nixos), which is
mirrored to `cintienrico-prog/MyCV` (public) after each push; Overleaf's own GitHub integration is no longer used.
`flake.nix` has the GitHub mirror as non-flake input `cv-src` (reachable from CI, unlike the VPS, which is
tailnet-only) and builds `static/cv.pdf` from it at site build time. To publish a CV change: edit in Overleaf
(reaches GitHub within ~10 minutes) or `projects-save MyCV -m "…"` (seconds), then `nix flake update cv-src`,
commit `flake.lock`, push. Extra LaTeX packages go in `texliveMedium.withPackages` (texlive.combine is deprecated).

Theme: palettes live in `data/palettes.toml` (20: catppuccin, rose-pine, nord, tokyo-night, everforest, gruvbox,
kanagawa, dracula, solarized, one, ayu, terminal, monokai, github, nightfox, material, zenburn, oxocarbon, void, ember; each with `dark` + `light`). Pick one with `palette = "…"` and
optionally force `scheme = "dark"|"light"` (default `auto`) in `config.toml` [extra]. `templates/base.html` generates the CSS
variables and the favicon (data URI) from it; `static/style.css` holds no colours. Text colours were nudged to WCAG AA
(4.5:1), so values differ slightly from the official palettes. To add a palette, copy a block in `palettes.toml`.
About-page photo: `photo` and `photo_style` = "greyscale"|"duotone"|"plain" in config.toml [extra]; the tints are an SVG gradient
map (page.html) between palette colours set per scheme in base.html, so they follow the palette. `nix flake check` validates `photo_style`.

## Status (2026-11-04, updated 2026-11-20)

Done:
- Site scaffolded (this repo), builds with zola; screenshots checked desktop/mobile/light mode.
- Config patch applied on the Mac and rebuilt (direnv module, projects.list).
- `gh` rebuilt, authenticated (SSH); direnv works.
- Templates ported to Tera 2; `nix build .#site` and `.#preview` pass; `zola serve` checked.

To do, in order (steps 1–3, 5 and 6 done as of 2026-11-11: repo public, Pages on, github.io prototype deploying;
content TODOs are Enrico's to fix):
1. `rebuild-mba` (picks up `gh`); check `direnv version`, `gh --version`.
2. `gh auth login` (GitHub.com, SSH protocol, browser login) — interactive, Enrico runs it.
3. In this repo: `direnv allow`; `nix build .#site` (never tested on a real machine yet:
   the sandbox where it was written could not fetch nixpkgs); `zola serve` and look at it.
4. Content TODOs before going public:
   - `content/about.md`: first paragraph guesses his current position — he rewrites it.
   - `data/teaching.toml`: two guessed 2026–27 UvA entries; Bologna years after 2022 missing.
   - `data/publications.bib`: co-author order on multi-author papers is a guess; "Quo Vadis Wheeler-DeWitt Time?" has no DOI.
   - add CV (About links to `/cv.pdf`, built from MyCV); optional photo → `static/img/photo.jpg` + `photo` in `config.toml`.
   - `config.toml` links: maybe add ORCID / PhilPapers / Scholar, drop Facebook/Instagram.
   - `git add` new files: the flake only sees tracked files.
5. `gh repo create cintienrico-prog/enricocinti.com --public --source . --push`
6. Enable Pages from Actions: `gh api -X POST repos/cintienrico-prog/enricocinti.com/pages -f build_type=workflow`;
   then `gh run watch` (re-run the first run if it failed before Pages was enabled).
7. Browser, by Enrico: GitHub account Settings → Pages → verify `enricocinti.com` (TXT `_github-pages-challenge-cintienrico-prog` at Namecheap).
8. Namecheap Advanced DNS (BasicDNS): remove Google Sites records (CNAME www → ghs.googlehosted.com, any @ redirect/A);
   add A @ → 185.199.108.153 / .109.153 / .110.153 / .111.153 and CNAME www → cintienrico-prog.github.io.
   Leave MX/other TXT alone.
9. Set custom domain via `gh api` (above); check with `dig +short enricocinti.com` / `www.enricocinti.com`;
   once the certificate exists: `gh api -X PUT repos/cintienrico-prog/enricocinti.com/pages -F https_enforced=true`.
10. Retire Google Sites: remove custom domain, unpublish.

## Ideas for later

- Font: JetBrains Mono woff2 (latin subset, from @fontsource) is committed in `static/fonts/` with its OFL licence;
  could instead come from nixpkgs at build time.
- CV built from `cv/cv.tex` (flake already supports it).
- A Claude Code skill "add paper <DOI>": fetch Crossref metadata, write the BibTeX entry, preview, commit.

## Checks

`nix flake check` runs in CI before every deploy (a failure leaves the live site untouched) and works locally:
`site` (full build incl. CV and BibTeX), `zola-check` (internal links; external skipped, no network in the sandbox),
`palettes` (every palette has all keys as #rrggbb; `palette`/`scheme` in config.toml are valid). `mkSite` etc. live in
a `build` helper in `flake.nix`, not in `packages` (only derivations may be there).
