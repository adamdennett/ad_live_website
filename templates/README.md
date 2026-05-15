# Templates

Drop-in files for sister repos that want to auto-render and surface
blog posts on adamdennett.co.uk.

## Setting up auto-render in a new repo

To enable in a project repo (say, `widget-analysis`) so you can write
blog posts directly on github.com without rendering locally:

1. **Copy the three files at the repo root** of the target repo:
   - `.github/workflows/render-blogs.yml` ← from `templates/render-blogs.yml`
   - `_blog-style.css` ← from `templates/_blog-style.css`
   - `_blog-format.yml` ← from `templates/_blog-format.yml`

2. **Add `docs/.nojekyll`** in the target repo. It can be empty —
   just needs to exist. Stops GitHub Pages' Jekyll from filtering
   files starting with `_` (which would otherwise hide
   `_blog-style.css`).

3. **Confirm Pages is enabled** and serving from `main/docs`
   (`gh api repos/adamdennett/widget-analysis/pages` to check). If the
   repo uses `build_type: workflow`, switch to legacy:
   `gh api -X PUT repos/adamdennett/widget-analysis/pages -f build_type=legacy`.

4. **Confirm `_quarto.yml` has `output-dir: docs`** (Quarto's
   default project layout for this purpose).

5. **Confirm `.gitignore` doesn't exclude `docs/`** — easy thing to
   miss; without it, the auto-commit step silently does nothing.

Then to write a blog post: in the target repo on github.com, click
**Add file → Create new file**, name it `blog1.qmd` (or `blog2.qmd`,
etc.) at the repo root, paste this front-matter and your post:

```yaml
---
title: "A short writeup on …"
description: "One-line description."
date: 2026-05-20
image: thumb.png        # optional; relative path inside the repo or full URL
# draft: true           # uncomment to hide while drafting
---

Body of the post goes here…
```

Commit. Within ~30 seconds the `Render blog posts` workflow finishes,
auto-commits `docs/blog1.html` and `docs/_blog-style.css`, Pages
serves them at `https://adamdennett.github.io/widget-analysis/blog1.html`,
and adamdennett.co.uk's Blog page picks the post up on its next
render (push, manual trigger, or the daily 05:30 UTC cron).

## What's in each file

| File | Role |
|------|------|
| `render-blogs.yml`   | The GitHub Actions workflow |
| `_blog-style.css`    | Slim CSS that matches the adamdennett.co.uk look (Fraunces serif headings, Inter body, JetBrains Mono code, paper background, terracotta accent) |
| `_blog-format.yml`   | Quarto metadata applied via `--metadata-file` so only `blog*.qmd` files get the styling — other qmds in the project (analysis, slides, etc.) are unaffected |

## R code chunks in blog posts

The default workflow ships with no R setup, so it renders pure-prose
posts in ~10 seconds. If a post needs ```{r}``` code chunks,
uncomment the `setup-r` / `setup-r-dependencies` steps in
`render-blogs.yml` and list the packages your code uses.
