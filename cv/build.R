# Builds cv.pdf and publications.pdf. Run locally with `Rscript cv/build.R`;
# CI runs it on every site render (see .github/workflows/publish.yml).
setwd(here::here("cv"))
# Locally, use the pandoc that ships with Quarto so we don't need a
# separate install. CI has pandoc on the PATH already.
quarto_pandoc <- "C:/Program Files/Quarto/bin/tools"
if (dir.exists(quarto_pandoc)) Sys.setenv(RSTUDIO_PANDOC = quarto_pandoc)
rmarkdown::render("cv.Rmd", output_file = "cv.pdf")
rmarkdown::render("publications.Rmd", output_file = "publications.pdf")
