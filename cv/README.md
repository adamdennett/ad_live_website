# CV and publications PDF — vitae source

Two PDFs are built here with the
[`vitae`](https://github.com/mitchelloharawild/vitae) R package and the
`awesomecv` template (LaTeX-based, rendered with `xelatex` via TinyTeX):

| Source | Output | Linked from |
|--------|--------|-------------|
| [`cv.Rmd`](cv.Rmd) | `cv.pdf` | the CV page ([`cv.qmd`](../cv.qmd)) |
| [`publications.Rmd`](publications.Rmd) | `publications.pdf` | the "Download this list (PDF)" button on the publications page |

Both share [`preamble.tex`](preamble.tex) (fonts and colours matching the
website) and the bundled fonts in [`fonts/site/`](fonts/site/).

## What comes from ORCID

Both documents call [`_helpers/orcid.R`](../_helpers/orcid.R), the same
code the website's publications page uses, so all three always list the
same papers.

- **Selected Publications** (CV) — every ORCID work since
  `CV_PUBS_SINCE` (2020), except theses, preprints and anything in
  `cv_pubs_exclude`. To drop a paper from the CV, add its DOI or the
  start of its title to `cv_pubs_exclude` in `cv.Rmd`.
- **Grants** (CV) — the hand-kept `grants_manual` list is the
  authoritative record (ORCID has no roles, and not every grant is on
  it). Any ORCID grant not already in that list — matched by grant
  number in the title, or by title — is appended automatically. To hide
  an ORCID grant, add its grant number to `orcid_grants_hide`. The
  "External grants total" figure is still typed by hand.
- **publications.pdf** — every ORCID work, newest first, the same as
  the publications page.

Everything else in the CV (history, education, talks, supervision…) is
hand-edited in `cv.Rmd`.

## Rebuilds

CI rebuilds both PDFs on every site render — every push to `main` and
the daily 05:30 UTC cron — so new ORCID entries reach the CV the same
day they reach the publications page. If the LaTeX step ever fails, CI
carries on and publishes the last committed PDFs.

The PDFs CI builds are published, not committed back, so the copies in
git only change when you rebuild locally.

To rebuild locally (e.g. to preview a change to `cv.Rmd`):

```powershell
Rscript cv/build.R
```

`build.R` renders both PDFs, using Quarto's bundled pandoc when it finds
it. TinyTeX installs any missing LaTeX packages on first build.

See [`.gitignore`](../.gitignore) for the vitae build artefacts that
don't get committed (`awesome-cv.cls`, `cv.log`, `cv.tex`).

## How the PDFs reach the website

- The project-level [`_quarto.yml`](../_quarto.yml) lists `cv/cv.pdf`,
  `cv/cv.Rmd` and `cv/publications.pdf` under `project.resources`, so
  they are copied into the rendered site.
- [`cv.qmd`](../cv.qmd) embeds `cv/cv.pdf` and offers download links.
- A render exclude (`!cv/**` in `project.render`) stops Quarto from
  trying to render the `.Rmd` files as website pages.
