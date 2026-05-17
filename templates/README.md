# Templates

Drop-in files for sister repos that want to auto-render and surface
blog posts on adamdennett.co.uk.

## Already installed

The blog-post auto-render template is installed in all of Adam's
Pages-enabled featured-project repos: `BH_Schools_2`,
`BH_Schools_Consultation`, `school_attainment_tool`,
`BrightonRestaurantsMap`, `defibrillator-analysis`,
`west_london_alliance`, `EPC_Analysis_Website`,
`EPC_Data_Analysis`, `Synthetic-LS-spines`, `SIModelling`. To
install it into a new repo, follow the checklist below — or run
[`_install_blog_template.py`](../_install_blog_template.py) (an
ad-hoc script we used for the bulk install) with the target repo
added to the `TARGETS` list.

## Setting up auto-render in a new repo

To enable in a project repo (say, `widget-analysis`) so you can write
blog posts directly on github.com without rendering locally:

1. **Copy the three files at the repo root** of the target repo:
   - `.github/workflows/render-blogs.yml` ← from `templates/render-blogs.yml`
   - `_blog-style.css` ← from `templates/_blog-style.css`
   - `_blog-format.yml` ← from `templates/_blog-format.yml`

2. **Add `.nojekyll`** in the target repo at the **Pages-served root**:
   - If Pages serves from `main/docs`: file at `docs/.nojekyll`
   - If Pages serves from `main/` (repo root): file at `.nojekyll`

   It can be empty. Without it, GitHub Pages' Jekyll filters out
   `_blog-style.css` (since it starts with `_`) and posts render
   unstyled.

3. **Confirm Pages is enabled** with `build_type: legacy`
   (`gh api repos/adamdennett/widget-analysis/pages` to check).
   If it says `build_type: workflow`, switch:
   `gh api -X PUT repos/adamdennett/widget-analysis/pages -f build_type=legacy`.

4. **`_quarto.yml` doesn't need to change.** The workflow uses
   whatever the repo's existing Quarto setup says — if the repo
   has `output-dir: docs`, the rendered blog post lands in `docs/`;
   if not, it lands at the repo root next to the `.qmd`. Either
   way Pages serves it.

5. **Confirm `.gitignore` doesn't exclude the Pages-served
   directory** (`docs/` or the repo root). Without that, the
   auto-commit step silently stages nothing.

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
