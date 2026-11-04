# CLAUDE.md — enricocinti.com

Context for Claude Code sessions in this repo. Written at the end of the claude.ai
chat where the site was designed (2026-11-04); keep it updated as things change.

## What this is

Enrico Cinti's academic website (philosopher of physics, University of Amsterdam).
It replaces a Google Sites site at www.enricocinti.com. Goals he set:

- off Google Sites, managed as plain files in git;
- built with Nix; free hosting;
- terminal-style design (references: bashbunni.dev, terminal.shop and its
  "sold out" screen: dark, monospace, orange accent, TUI-like panels);
- keep the old functionality: home, about + CV, publications with abstracts, teaching, contact links.

He is fluent in Nix (NixOS + nix-darwin, hjem, flakes) but new to web hosting.
Explain web/DNS steps; don't explain Nix basics. Treat his corrections as authoritative.
Anything published under his name (About text etc.) must read as his own voice:
draft only when asked, and keep it plain, not LLM-ish.

## Decisions made

- Generator: Zola (single binary, in nixpkgs). Templates are custom, not a Zola theme.
- Publications: `data/publications.bib`, loaded with Zola's `load_data(format="bibtex")`.
  Author lists use "First Last and First Last"; his own name is hidden and the rest shown as "with …".
  The BibTeX parser fails on an `@` anywhere outside entries, including comments.
- Teaching: `data/teaching.toml`.
- Hosting: GitHub Pages, deployed by `.github/workflows/deploy.yml` (`nix build .#site`,
  `cp -rL result public`, upload-pages-artifact, deploy-pages). Repo must be public.
- With Actions deploys GitHub ignores `static/CNAME`: the custom domain is set in
  repo Settings → Pages (or `gh api -X PUT repos/cintienrico-prog/enricocinti.com/pages -f cname=www.enricocinti.com`).
- Domain: stays at Namecheap for now (~$14.78/yr renewal). Moving to Cloudflare (~$9/yr) is optional, later.
- Self-hosting on a VPS: not now. Possible later by adding this flake as an input to a NixOS server and serving `packages.site` with Caddy.
- Kept as its own flake, not inside his system config. His config (`~/nixos`, jj + git)
  only provides direnv/nix-direnv (`modules/direnv.nix`), `gh` (`modules/vcs`), and lists
  this repo in `modules/shell/dotfiles/projects.list` so `projects-sync`/`projects-save` cover it.
  Note: `projects-save` pushes to `main`, which deploys.

## Machines

- enrico-mba: M1 MacBook Air, nix-darwin, user `enricocinti`, rebuild with `rebuild-mba`. Currently the only machine available.
- The Blade (NixOS, user `enrico`) is away for repair; set it up later with `sync`, `rebuild`, `projects-sync`, `direnv allow`.
- Shell is fish. GitHub user: `cintienrico-prog`.

## Status (2026-11-04)

Done:
- Site scaffolded (this repo), builds with zola; screenshots checked desktop/mobile/light mode.
- Config patch applied on the Mac and rebuilt (direnv module, projects.list).
- `gh` added to `modules/vcs/default.nix` — NOT yet rebuilt.

To do, in order:
1. `rebuild-mba` (picks up `gh`); check `direnv version`, `gh --version`.
2. `gh auth login` (GitHub.com, SSH protocol, browser login) — interactive, Enrico runs it.
3. In this repo: `direnv allow`; `nix build .#site` (never tested on a real machine yet:
   the sandbox where it was written could not fetch nixpkgs); `zola serve` and look at it.
4. Content TODOs before going public:
   - `content/about.md`: first paragraph guesses his current position — he rewrites it.
   - `data/teaching.toml`: two guessed 2026–27 UvA entries; Bologna years after 2022 missing.
   - `data/publications.bib`: co-author order on multi-author papers is a guess; "Quo Vadis Wheeler-DeWitt Time?" has no DOI.
   - add `static/cv.pdf` (About links to it); optional photo → `static/img/photo.jpg` + `photo` in `config.toml`.
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

- `.github/workflows`: run `nix flake check` before deploy; add flake `checks` (zola check, bib parse).
- Font from nixpkgs (e.g. `pkgs.nerd-fonts.terminess-ttf`, which he uses in his terminal) converted to woff2 at build time.
- Named colour palettes selectable from `config.toml`.
- CV built from `cv/cv.tex` (flake already supports it).
- A Claude Code skill "add paper <DOI>": fetch Crossref metadata, write the BibTeX entry, preview, commit.
