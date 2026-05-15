# Templates

Drop-in workflow files for sister repos.

## `render-blogs.yml`

Auto-renders any `blog*.qmd` at the root of a project repo to `docs/`,
so blog posts can be authored directly on github.com without a local
R/Quarto setup.

**To enable in a new repo:**

1. Copy `render-blogs.yml` to that repo at
   `.github/workflows/render-blogs.yml`.
2. Make sure the repo has Pages enabled, serving from `main`/`docs`.
3. Make sure `_quarto.yml` says `output-dir: docs`.
4. Make sure `.gitignore` doesn't exclude `docs/`.

After that, pushing a `blog1.qmd` at the repo root will trigger an
auto-render. The rendered HTML lands at
`https://adamdennett.github.io/<repo>/blog1.html`, and
adamdennett.co.uk's Blog page picks it up on its next render (push,
manual trigger, or the daily 05:30 UTC cron).

**If a post needs R code chunks**, uncomment the `setup-r` /
`setup-r-dependencies` steps in the workflow and list the R packages
the code uses.
