# Shared helper: fetch GitHub repos tagged with a given `type` in their
# README front-matter and render them as project-cards.
#
# Usage (in a Quarto chunk with `#| output: asis`):
#   source("../_helpers/gh_type_cards.R")
#   render_gh_type_cards("teaching")

library(httr2)
library(jsonlite)
library(dplyr)
library(purrr)
library(htmltools)
library(lubridate)
library(yaml)
library(stringr)

gh_token <- function() {
  Sys.getenv("GITHUB_PAT", unset = Sys.getenv("GITHUB_TOKEN"))
}

gh_req <- function(url) {
  req <- request(url) |>
    req_headers("Accept" = "application/vnd.github+json",
                "X-GitHub-Api-Version" = "2022-11-28") |>
    req_error(is_error = function(resp) FALSE)
  pat <- gh_token()
  if (nzchar(pat)) req <- req_auth_bearer_token(req, pat)
  req
}

fetch_repos <- function(user = "adamdennett") {
  gh_req(sprintf("https://api.github.com/users/%s/repos?per_page=100&type=owner&sort=updated", user)) |>
    req_perform() |>
    resp_body_json()
}

fetch_readme <- function(repo_full_name, default_branch) {
  url <- sprintf("https://raw.githubusercontent.com/%s/%s/README.md",
                 repo_full_name, default_branch)
  resp <- gh_req(url) |> req_perform()
  if (resp_status(resp) != 200) return(NULL)
  resp_body_string(resp)
}

split_frontmatter <- function(text) {
  if (is.null(text) || !nzchar(text)) return(list(meta = list(), body = ""))
  m <- regmatches(text,
                  regexec("(?s)^---[ \t]*\r?\n(.*?)\r?\n---[ \t]*\r?\n(.*)$",
                          text, perl = TRUE))[[1]]
  if (length(m) < 3) return(list(meta = list(), body = text))
  meta <- tryCatch(yaml::yaml.load(m[2]), error = function(e) list())
  if (!is.list(meta)) meta <- list()
  list(meta = meta, body = m[3])
}

first_image_in_body <- function(body) {
  if (!nzchar(body)) return(NULL)
  m <- regmatches(body, regexec("(?s)!\\[[^\\]]*\\]\\(([^)\\s]+)",
                                body, perl = TRUE))[[1]]
  if (length(m) >= 2) m[2] else NULL
}

absolutize_image <- function(image, repo_full_name, default_branch) {
  if (is.null(image) || !nzchar(image)) return(NA_character_)
  if (grepl("^https?://github\\.com/[^/]+/[^/]+/blob/", image)) {
    return(sub("^https?://github\\.com/([^/]+)/([^/]+)/blob/",
               "https://raw.githubusercontent.com/\\1/\\2/", image))
  }
  if (grepl("^https?://", image)) return(image)
  image <- sub("^\\./", "", image)
  sprintf("https://raw.githubusercontent.com/%s/%s/%s",
          repo_full_name, default_branch, image)
}

# ---------------------------------------------------------------------------
# Cross-repo blog post discovery
# ---------------------------------------------------------------------------
# Scans every non-archived, non-fork, Pages-enabled owner repo for files
# matching `blog*.qmd` at the repo root (case-insensitive). For each
# match, fetches the raw .qmd, parses its YAML front-matter, and returns
# a card-shaped tibble.
#
# Conventions:
# - The .qmd must be rendered to HTML in its host repo before the link
#   works. Default URL is {pages_root}/{filename}.html; override via a
#   `site:` field in the .qmd's front-matter.
# - Front-matter fields used: title, description, date, image, draft, site
# - Drafts (front-matter `draft: true`) are skipped.

find_blog_qmds_across_repos <- function(user = "adamdennett") {
  repos <- fetch_repos(user)
  repos <- keep(repos, function(r) {
    isTRUE(r$has_pages) && !isTRUE(r$archived) && !isTRUE(r$fork)
  })

  cards <- list()

  for (r in repos) {
    branch   <- r$default_branch %||% "main"
    tree_url <- sprintf("https://api.github.com/repos/%s/git/trees/%s",
                        r$full_name, branch)

    tree_resp <- tryCatch(gh_req(tree_url) |> req_perform(),
                          error = function(e) NULL)
    if (is.null(tree_resp) || resp_status(tree_resp) != 200) next

    tree <- resp_body_json(tree_resp)$tree
    blog_files <- keep(tree, function(t) {
      identical(t$type, "blob") &&
        grepl("^blog\\d*\\.qmd$", t$path, ignore.case = TRUE)
    })
    if (length(blog_files) == 0) next

    pages_root <- sprintf("https://adamdennett.github.io/%s/", r$name)

    for (bf in blog_files) {
      raw_url <- sprintf("https://raw.githubusercontent.com/%s/%s/%s",
                         r$full_name, branch, bf$path)
      raw <- tryCatch(
        request(raw_url) |> req_perform() |> resp_body_string(),
        error = function(e) ""
      )
      if (!nzchar(raw)) next

      parts <- split_frontmatter(raw)
      fm    <- parts$meta

      if (isTRUE(fm$draft)) next   # respect draft flag

      base  <- tools::file_path_sans_ext(bf$path)
      live_url <- if (!is.null(fm$site) && nzchar(fm$site)) {
        paste0(pages_root, sub("^/", "", fm$site))
      } else {
        sprintf("%s%s.html", pages_root, base)
      }

      img      <- fm$image %||% first_image_in_body(parts$body)
      img_url  <- absolutize_image(img, r$full_name, branch)

      cards[[length(cards) + 1]] <- tibble(
        title       = fm$title       %||% bf$path,
        description = fm$description %||% "",
        date        = suppressWarnings(as.Date(fm$date %||% NA)),
        url         = live_url,
        image_url   = img_url,
        repo        = r$name,
        repo_url    = r$html_url
      )
    }
  }

  if (length(cards) == 0) return(tibble())
  bind_rows(cards) |> arrange(desc(date))
}

render_blog_qmds_across_repos <- function(user = "adamdennett") {
  cards <- find_blog_qmds_across_repos(user)

  if (nrow(cards) == 0) {
    cat("\n*Nothing here yet — drop a `blog*.qmd` at the root of any of ",
        "my Pages-enabled repos with a YAML front-matter block ",
        "(title, date, description, image), render the project, and it ",
        "will appear here on the next site rebuild.*\n", sep = "")
    return(invisible())
  }

  render_card <- function(row) {
    has_image <- !is.na(row$image_url) && nzchar(row$image_url)
    has_desc  <- !is.na(row$description) && nzchar(row$description)

    image_block <- if (has_image) {
      a(href = row$url, target = "_blank", class = "project-image-link",
        tags$img(src = row$image_url, alt = row$title,
                 loading = "lazy", class = "project-image"))
    }

    div(class = paste("project-card",
                      if (has_image) "with-image" else "no-image"),
        image_block,
        div(class = "project-card-body",
            h3(class = "project-title",
               a(href = row$url, target = "_blank", row$title)),
            if (has_desc)
              p(class = "project-desc", row$description),
            div(class = "project-meta",
                if (!is.na(row$date))
                  span(class = "badge date", format(row$date, "%b %Y")),
                span(class = "badge lang", row$repo)
            ),
            div(class = "project-links",
                a(href = row$url,      target = "_blank", "Read →"),
                a(href = row$repo_url, target = "_blank", "Source")
            )
        )
    )
  }

  rendered <- lapply(split(cards, seq_len(nrow(cards))), render_card)
  cat("\n```{=html}\n")
  cat(as.character(div(class = "project-grid", rendered)))
  cat("\n```\n")
  invisible()
}

render_gh_type_cards <- function(type_filter) {
  repos <- fetch_repos()

  base_df <- map_dfr(repos, function(r) {
    tibble(
      name           = r$name,
      full_name      = r$full_name,
      default_branch = r$default_branch %||% "main",
      description    = r$description %||% "",
      has_pages      = isTRUE(r$has_pages),
      archived       = isTRUE(r$archived),
      updated        = as_date(ymd_hms(r$updated_at)),
      repo_url       = r$html_url,
      pages_root     = sprintf("https://adamdennett.github.io/%s/", r$name)
    )
  }) |>
    filter(has_pages, !archived) |>
    arrange(desc(updated))

  enrich <- function(name, full_name, default_branch) {
    readme <- tryCatch(fetch_readme(full_name, default_branch), error = function(e) NULL)
    if (is.null(readme)) {
      return(tibble(meta_title = NA_character_, meta_description = NA_character_,
                    meta_site = NA_character_, meta_image = NA_character_,
                    meta_type = NA_character_))
    }
    parts <- split_frontmatter(readme)
    meta <- parts$meta
    img <- meta$image %||% first_image_in_body(parts$body)
    tibble(
      meta_title       = meta$title       %||% NA_character_,
      meta_description = meta$description %||% NA_character_,
      meta_site        = meta$site        %||% NA_character_,
      meta_image       = absolutize_image(img, full_name, default_branch),
      meta_type        = tolower(trimws(meta$type %||% NA_character_))
    )
  }

  enriched <- pmap_dfr(
    list(base_df$name, base_df$full_name, base_df$default_branch),
    enrich
  )

  filtered_df <- bind_cols(base_df, enriched) |>
    filter(!is.na(meta_type) & meta_type == type_filter) |>
    mutate(
      display_title       = coalesce(meta_title, name),
      display_description = coalesce(na_if(meta_description, ""), na_if(description, "")),
      pages_url           = ifelse(!is.na(meta_site) & nzchar(meta_site),
                                   paste0(pages_root, sub("^/", "", meta_site)),
                                   pages_root),
      image_url           = meta_image
    )

  if (nrow(filtered_df) > 0) {
    card <- function(row) {
      has_image <- !is.na(row$image_url) && nzchar(row$image_url)
      has_desc  <- !is.na(row$display_description) && nzchar(row$display_description)

      image_block <- if (has_image) {
        a(href = row$pages_url, target = "_blank", class = "project-image-link",
          tags$img(src = row$image_url, alt = row$display_title,
                   loading = "lazy", class = "project-image"))
      }

      div(class = paste("project-card", if (has_image) "with-image" else "no-image"),
          image_block,
          div(class = "project-card-body",
              h3(class = "project-title",
                 a(href = row$pages_url, target = "_blank", row$display_title)),
              if (has_desc)
                p(class = "project-desc", row$display_description)
              else
                p(class = "project-desc project-desc-empty", em("(no description)")),
              div(class = "project-meta",
                  span(class = "badge date",
                       paste0("Updated ", format(row$updated, "%b %Y")))
              ),
              div(class = "project-links",
                  a(href = row$pages_url, target = "_blank", "Live site →"),
                  a(href = row$repo_url,  target = "_blank", "Source")
              )
          )
      )
    }

    cards <- lapply(split(filtered_df, seq_len(nrow(filtered_df))), card)

    cat("\n```{=html}\n")
    cat(as.character(div(class = "project-grid", cards)))
    cat("\n```\n")
  } else {
    cat(sprintf("\n*No GitHub repos tagged `type: %s` found.*\n", type_filter))
  }
}
