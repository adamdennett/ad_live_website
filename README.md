# adamdennett.co.uk — Quarto rebuild

A Quarto website replacing the old Hugo-Apéro version of `adamdennett.co.uk`.

## Structure

| Path | Purpose |
|------|---------|
| `_quarto.yml` | Site config (navbar, theme, footer, OpenGraph) |
| `index.qmd` | Home page with intro + social links |
| `about.qmd` | About page |
| `projects.qmd` | **Live** gallery of GitHub Pages projects, pulled from the GitHub API at render time |
| `blog/` | Blog listing; posts live in `blog/posts/<slug>/index.qmd` |
| `talks/` | Talks listing; one folder per talk |
| `teaching/` | Teaching listing; one folder per item |
| `styles.css` | Custom CSS for project cards and badges |
| `assets/` | Site-wide images (headshot, avatar) |
| `_extensions/` | Quarto extensions (academicons) |
| `.github/workflows/publish.yml` | CI: render and publish to GitHub Pages on push |

## Local preview

```bash
quarto preview
```

## Build

```bash
quarto render
```

Output goes to `_site/`.

## Publishing

### GitHub Pages (recommended — automatic)

The repo includes `.github/workflows/publish.yml`. On push to `main` it:

1. Installs Quarto and R 4.5.2.
2. Installs the R packages used by `projects.qmd`.
3. Runs `quarto publish gh-pages`, which renders the site and pushes the
   output to a `gh-pages` branch.

One-time setup on GitHub:

1. Push this repo to GitHub.
2. Repository **Settings → Pages → Source: Deploy from a branch → Branch: `gh-pages` / root**.
3. (Optional, for custom domain `adamdennett.co.uk`) add a `CNAME` file at
   the project root containing just `adamdennett.co.uk`, and configure DNS
   to point at GitHub Pages (`185.199.108.153`, `.109.153`, `.110.153`,
   `.111.153` for A records, or a CNAME to `adamdennett.github.io`).

### GitHub Pages (manual, from your laptop)

If you'd rather not use CI:

```bash
quarto publish gh-pages
```

This requires you to be on `main`, with a clean working tree, and pushes
the built `_site/` to the `gh-pages` branch of the configured remote.

### Quarto Pub

```bash
quarto publish quarto-pub
```

First time, it'll open a browser to authenticate and ask which account /
slug to publish under. The chosen slug is remembered in `_publish.yml`
(which gets created automatically — you can commit it if you want CI to
re-use it).

## Refreshing the projects page

`projects.qmd` calls the GitHub API every time it's rendered, so re-rendering
will pull the current set of repos with GitHub Pages enabled. To curate:

- Edit the `exclude` vector in the setup chunk to hide repos.
- Edit the `categories` list to group repos under section headings; anything
  not listed lands in "Other".

Set `GITHUB_PAT` (or `GITHUB_TOKEN`) in your environment if you hit rate
limits — for an anonymous user that's 60 requests/hour. The CI workflow
sets `GITHUB_TOKEN` for you.

## Adding content

- **Blog post:** `blog/posts/YYYY-MM-DD-slug/index.qmd` with frontmatter
  `title`, `date`, `description`, `categories`, optional `image`.
- **Talk:** `talks/YYYY-MM-DD-slug/index.qmd` — same shape.
- **Teaching item:** `teaching/YYYY-MM-DD-slug/index.qmd` — same shape; the
  listing uses a grid layout, so an `image:` is encouraged.

To draft without publishing, add `draft: true` to the frontmatter.

## R packages required

- `httr2`, `jsonlite`, `dplyr`, `purrr`, `htmltools`, `lubridate`, `knitr`, `rmarkdown`

```r
install.packages(c("httr2", "jsonlite", "dplyr", "purrr",
                   "htmltools", "lubridate", "knitr", "rmarkdown"))
```
