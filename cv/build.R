setwd("E:/ad_live_website/cv")
# Use the pandoc that ships with Quarto so we don't need a separate install
Sys.setenv(RSTUDIO_PANDOC = "C:/Program Files/Quarto/bin/tools")
rmarkdown::render("cv.Rmd", output_file = "cv.pdf")
