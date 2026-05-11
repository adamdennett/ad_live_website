# CV — vitae source

The CV (`cv.pdf`) is generated from [`cv.Rmd`](cv.Rmd) using the
[`vitae`](https://github.com/mitchelloharawild/vitae) R package and the
`awesomecv` template (LaTeX-based, rendered with `xelatex` via TinyTeX).

## Rebuild locally

```r
# from the project root (E:/ad_live_website)
setwd("cv")
# rmarkdown needs a pandoc; use the one Quarto already bundles:
Sys.setenv(RSTUDIO_PANDOC = "C:/Program Files/Quarto/bin/tools")
rmarkdown::render("cv.Rmd", output_file = "cv.pdf")
```

Or run the helper script:

```powershell
Rscript cv/build.R
```

See [`.gitignore`](../.gitignore) for the list of vitae build artefacts
that don't get committed (`awesome-cv.cls`, `fonts/`, `cv.log`, `cv.tex`).

## How the CV reaches the website

- `cv.pdf` is committed to this folder.
- The project-level [`_quarto.yml`](../_quarto.yml) lists `cv/cv.pdf` and
  `cv/cv.Rmd` under `project.resources`, so both are copied into the
  rendered site.
- [`cv.qmd`](../cv.qmd) at the project root embeds `cv/cv.pdf` in an
  `<object>` and offers download links for the PDF and the source.
- A render exclude (`!cv/**` in `project.render`) stops Quarto from
  trying to render `cv.Rmd` itself as a website page.

## Updating

1. Edit `cv.Rmd`.
2. Rebuild as above (regenerates `cv.pdf`).
3. `quarto preview` to check it on the website.
4. Commit both `cv.Rmd` and the updated `cv.pdf`.

CI does **not** rebuild the CV — TinyTeX isn't installed in the workflow.
That keeps each CI run fast, but it means *you must rebuild the CV locally
and commit the new `cv.pdf`* whenever the source changes.
