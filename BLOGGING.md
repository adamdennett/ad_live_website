# How to write a blog post on adamdennett.co.uk

Blog posts on this site can live in **any** of my GitHub repos. The site
discovers them automatically — drop a `blog*.qmd` file at the repo root,
push, and within ~24 hours the post appears on
[adamdennett.co.uk/blog/](https://adamdennett.co.uk/blog/).

## TL;DR — write a post in 30 seconds

**All 10 repos featured on the [Projects page](https://adamdennett.co.uk/projects.html)
are blog-ready right now.** They each have the auto-render workflow
and theme files installed:

| Project | Pages serves from |
|---|---|
| `BH_Schools_2`            | `/docs` |
| `BH_Schools_Consultation` | `/docs` |
| `school_attainment_tool`  | `/docs` |
| `BrightonRestaurantsMap`  | `/docs` |
| `defibrillator-analysis`  | `/docs` |
| `west_london_alliance`    | `/`     |
| `EPC_Analysis_Website`    | `/`     |
| `EPC_Data_Analysis`       | `/`     |
| `Synthetic-LS-spines`     | `/`     |
| `SIModelling`             | `/`     |

The two featured repos not yet set up are `bh_school_choice` and
`council_tax` — neither has GitHub Pages enabled. Enable Pages on
either of them and re-run the install script to add them too.

1. On github.com, open the repo. Click **Add file → Create new file**.
2. Name the file `blog1.qmd` at the repo root (or `blog2.qmd`,
   `blog3.qmd` … any `blog<number>.qmd`, or just `blog.qmd`).
3. Paste this template and replace the placeholders:

   ```yaml
   ---
   title: "A short writeup on …"
   description: "One-line description shown on the card."
   date: 2026-05-20
   image: thumb.png        # optional; relative path inside the repo or a full URL
   # site: blog1.html      # optional; override the rendered URL
   # draft: true           # uncomment to hide while drafting
   ---

   Body of the post goes here. Markdown formatting works:

   - bullet lists
   - **bold**, _italics_
   - [links](https://example.com)
   - `inline code`

   ## A heading

   …
   ```

4. Click **Commit changes**.

That's it. About 30 seconds later the `Render blog posts` workflow
finishes, `docs/blog1.html` is generated and committed for you, and
within 24 hours (or sooner if you trigger a website render) the post
appears on the Blog page.

## How to enable auto-render in a new repo

The workflow is reusable — copy four things from this repo's
[`templates/`](templates/) folder into the target repo. Full checklist
also lives in [`templates/README.md`](templates/README.md).

1. **Copy to the repo root:**
   - `.github/workflows/render-blogs.yml` ← from `templates/render-blogs.yml`
   - `_blog-style.css` ← from `templates/_blog-style.css`
   - `_blog-format.yml` ← from `templates/_blog-format.yml`

2. **Add `docs/.nojekyll`** in the target repo (it can be empty).
   Without it, Pages' Jekyll filter hides `_blog-style.css` and posts
   render unstyled.

3. **Confirm Pages settings:**
   - Source = `main` branch, `/docs` path
   - `build_type = legacy` (the default; if it says `workflow`, run
     `gh api -X PUT repos/adamdennett/<repo>/pages -f build_type=legacy`)

4. **Confirm `_quarto.yml`** has `output-dir: docs` (Quarto picks
   that up automatically for most project layouts).

5. **Confirm `.gitignore` doesn't exclude `docs/`.** Easy thing to
   miss; without it, the auto-commit step silently does nothing.

After all that, any `blog*.qmd` push triggers the workflow.

## R code chunks in posts

The default workflow renders only pure-prose posts (markdown text +
embedded images). That keeps each render to ~10 seconds and avoids
needing R + packages in CI.

If a post needs ```{r}``` code chunks, edit `render-blogs.yml` in
the target repo and uncomment the `setup-r` /
`setup-r-dependencies` steps. List the packages your code uses, e.g.:

```yaml
- uses: r-lib/actions/setup-r-dependencies@v2
  with:
    packages: |
      any::tidyverse
      any::sf
      any::leaflet
```

## The auto-render flow, step by step

```
You commit blog1.qmd on github.com
        ↓
.github/workflows/render-blogs.yml triggers (paths: blog*.qmd)
        ↓
GitHub Actions:
  1. checks out main
  2. installs Quarto
  3. runs `quarto render blog1.qmd --metadata-file _blog-format.yml`
     → applies _blog-style.css for typography + palette
     → output: docs/blog1.html  (+ optional docs/blog1_files/)
  4. stages docs/blog*.html, docs/blog*_files, docs/_blog-style.css
  5. commits + pushes with [skip ci] so it doesn't re-trigger itself
        ↓
GitHub Pages picks up the new docs/ on main → live URL works
        ↓
adamdennett.co.uk Blog page's daily 05:30 UTC cron (or any push)
re-renders → walks all Pages-enabled repos via the Trees API →
finds blog*.qmd, parses front-matter → builds a card linking to
https://adamdennett.github.io/<repo>/blog1.html
        ↓
Card appears on the Blog page
```

## How adamdennett.co.uk discovers blog posts

Look at the `## Posts from across my repos` section of
[`blog/index.qmd`](blog/index.qmd) — it calls
`render_blog_qmds_across_repos()` in
[`_helpers/gh_type_cards.R`](_helpers/gh_type_cards.R). That function:

1. Fetches every non-archived, non-fork, Pages-enabled owner repo
   (~50 calls).
2. For each, lists the root-level git tree.
3. Filters to files matching `^blog\d*\.qmd$`.
4. Fetches the raw qmd content, parses YAML front-matter.
5. Builds a card linking to `{pages_root}/{filename}.html` (or
   `pages_root + site` if the post's front-matter overrides it).

`freeze: false` on `blog/index.qmd` means this runs on every render,
so changes show up the next time the site rebuilds (push, manual, or
05:30 UTC daily cron).

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| Card appears, click → 404 | `blog1.qmd` is in the repo but never rendered to HTML | Trigger the workflow manually: `gh workflow run "Render blog posts" --repo adamdennett/<repo>`. Or push any small change to retry. |
| Card has broken thumbnail | `image:` path points at a file that doesn't exist | Check the front-matter `image:` against the repo contents. Either commit the missing file or fix the path. |
| Post looks unstyled (no Fraunces / Inter) | `docs/.nojekyll` is missing, so Pages filters out `_blog-style.css` | Add an empty `docs/.nojekyll` file to the target repo. |
| Workflow fails: "R not installed" or "package X not available" | Post contains ```{r}``` chunks but R setup is commented out | Uncomment the `setup-r` steps in `render-blogs.yml` and list the R packages used. |
| Post doesn't appear on adamdennett.co.uk | The website hasn't re-rendered yet (daily cron at 05:30 UTC), or the qmd has `draft: true` | Wait for the cron or trigger manually: `gh workflow run "Render and publish" --repo adamdennett/ad_live_website`. |
| Filename `blog_post.qmd` or `my-blog.qmd` doesn't appear | Discovery regex is `^blog\d*\.qmd$` — strict | Rename to `blog1.qmd` (or any `blog<number>.qmd`). |

## Front-matter cheatsheet

| Key | Required? | Description |
|-----|-----------|-------------|
| `title` | yes | Card title and page heading |
| `description` | recommended | One-line summary shown on the card |
| `date` | recommended | ISO date, used for sort order on the Blog page |
| `image` | optional | Thumbnail. Relative path inside the repo, github.com blob URL (auto-rewritten to raw), or full URL. If missing, the renderer uses the first `![](...)` image in the body. |
| `site` | optional | Override the rendered URL. Default is `{pages_root}/{basename}.html` — only set this if your Quarto project's output goes somewhere unusual. |
| `draft` | optional | `true` to skip the post (won't appear on the Blog page). |

## Files involved

| Where | What |
|-------|------|
| `blog/index.qmd` | Lists local blog posts (in `blog/posts/`), repos tagged `type: blog` in their README, and any `blog*.qmd` discovered across repos. |
| `_helpers/gh_type_cards.R` | `find_blog_qmds_across_repos()` and `render_blog_qmds_across_repos()` |
| `templates/render-blogs.yml` | Reusable GitHub Actions workflow |
| `templates/_blog-style.css` | Slim CSS matching adamdennett.co.uk look |
| `templates/_blog-format.yml` | Quarto `--metadata-file` payload |
| `templates/README.md` | Install checklist for new repos |
