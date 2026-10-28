# Shared ORCID fetchers for publications.qmd, cv/cv.Rmd and
# cv/publications.Rmd. Everything that shows publications or grants
# reads from here, so the website, the CV and the publications PDF
# always agree.

library(httr2)
library(dplyr)
library(purrr)
library(tibble)

ORCID <- "0000-0001-8036-0185"

orcid_req <- function(url) {
  request(url) |>
    req_headers(Accept = "application/json",
                `User-Agent` = "adamdennett.co.uk publications page")
}

# Fetch the full record for each put-code in parallel. `kind` is "work"
# or "funding". Failed requests come back as NULL.
orcid_details <- function(kind, put_codes, orcid = ORCID) {
  reqs <- map(put_codes, function(pc) {
    orcid_req(sprintf("https://pub.orcid.org/v3.0/%s/%s/%s", orcid, kind, pc))
  })
  resps <- req_perform_parallel(reqs, on_error = "continue", max_active = 8)
  map(resps, function(r) {
    if (inherits(r, "error") || resp_status(r) != 200) return(NULL)
    resp_body_json(r)
  })
}

# ---- Works ------------------------------------------------------------------

parse_work <- function(w) {
  if (is.null(w)) return(NULL)
  title <- w$title$title$value %||% NA_character_
  if (is.na(title) || !nzchar(title)) return(NULL)

  pdate <- w$`publication-date` %||% list()
  yr  <- suppressWarnings(as.integer(pdate$year$value))
  # Month and day are optional in ORCID; NA sorts to the end of its year.
  mon <- suppressWarnings(as.integer(pdate$month$value %||% NA))
  dy  <- suppressWarnings(as.integer(pdate$day$value %||% NA))

  journal <- (w$`journal-title` %||% list())$value %||% ""

  # External IDs — pull out DOI (preferred) or any other URL
  ext_ids <- (w$`external-ids` %||% list())$`external-id` %||% list()
  doi <- NA_character_
  for (eid in ext_ids) {
    if (identical(eid$`external-id-type`, "doi")) {
      doi <- eid$`external-id-value`; break
    }
  }

  # Work URL (often points at the publisher / DOI landing page)
  work_url <- (w$url %||% list())$value %||% NA_character_

  # Contributors (authors) — credit-name.value is the display name as
  # ORCID rendered it. Some works have empty contributor blocks.
  contributors <- (w$contributors %||% list())$contributor %||% list()
  authors <- map_chr(contributors, function(c) {
    (c$`credit-name` %||% list())$value %||% NA_character_
  })
  authors <- authors[!is.na(authors) & nzchar(authors)]

  tibble(
    title    = title,
    year     = yr,
    month    = mon,
    day      = dy,
    journal  = journal,
    type     = w$type %||% "",
    doi      = doi,
    work_url = work_url,
    authors  = list(authors)
  )
}

# Every work on the ORCID record, one row per paper, newest first.
orcid_works <- function(orcid = ORCID) {
  summary <- orcid_req(sprintf("https://pub.orcid.org/v3.0/%s/works", orcid)) |>
    req_perform() |>
    resp_body_json()

  # ORCID groups duplicate submissions of the same work (same DOI) into one
  # group with multiple work-summary entries (one per source — manual,
  # CrossRef, Scopus, ...). Pick the first put-code from each group as the
  # canonical entry, then fetch its full record (which has authors).
  put_codes <- map_chr(summary$group,
                       ~ as.character(.x$`work-summary`[[1]]$`put-code`))

  orcid_details("work", put_codes, orcid) |>
    map_dfr(parse_work) |>
    # Drop anything without a year (rare, makes grouping impossible)
    filter(!is.na(year)) |>
    # ORCID groups the same work submitted by multiple sources — but if
    # titles differ in casing or whitespace, they slip through and appear
    # twice. Collapse same-title-same-year duplicates, keeping the entry
    # with the strongest link (DOI > work URL > none).
    mutate(
      .norm = tolower(trimws(gsub("\\s+", " ", title))),
      .lnk  = ifelse(!is.na(doi) & nzchar(doi),           2L,
              ifelse(!is.na(work_url) & nzchar(work_url), 1L, 0L))
    ) |>
    group_by(.norm, year) |>
    slice_max(.lnk, n = 1, with_ties = FALSE) |>
    ungroup() |>
    select(-.norm, -.lnk) |>
    # Newest first within each year; undated-month papers last, by title.
    arrange(desc(year), desc(month), desc(day), title)
}

# ---- Fundings ---------------------------------------------------------------

parse_funding <- function(f) {
  if (is.null(f)) return(NULL)
  title <- f$title$title$value %||% NA_character_
  if (is.na(title) || !nzchar(title)) return(NULL)

  ext_ids <- (f$`external-ids` %||% list())$`external-id` %||% list()
  grant_id <- NA_character_
  for (eid in ext_ids) {
    if (identical(eid$`external-id-type`, "grant_number")) {
      grant_id <- eid$`external-id-value`; break
    }
  }

  amt <- f$amount %||% list()

  tibble(
    title      = title,
    start_year = suppressWarnings(as.integer((f$`start-date` %||% list())$year$value)),
    end_year   = suppressWarnings(as.integer((f$`end-date` %||% list())$year$value %||% NA)),
    funder     = (f$organization %||% list())$name %||% "",
    grant_id   = grant_id,
    amount     = suppressWarnings(as.numeric(amt$value %||% NA)),
    currency   = amt$`currency-code` %||% NA_character_
  )
}

# Every funding on the ORCID record, one row per grant, newest first.
orcid_fundings <- function(orcid = ORCID) {
  summary <- orcid_req(sprintf("https://pub.orcid.org/v3.0/%s/fundings", orcid)) |>
    req_perform() |>
    resp_body_json()

  # Same grouping as works: one group per grant, first summary wins.
  put_codes <- map_chr(summary$group,
                       ~ as.character(.x$`funding-summary`[[1]]$`put-code`))

  orcid_details("funding", put_codes, orcid) |>
    map_dfr(parse_funding) |>
    arrange(desc(start_year), title)
}

# ---- Formatting helpers -----------------------------------------------------

# "Claude E H Lynch" -> "Lynch, C.E.H."; names already in "Surname, X"
# form are left alone.
cite_name <- function(n) {
  n <- trimws(n)
  if (grepl(",", n)) return(n)
  parts <- strsplit(n, "\\s+")[[1]]
  if (length(parts) < 2) return(n)
  surname  <- parts[length(parts)]
  initials <- paste0(toupper(substr(parts[-length(parts)], 1, 1)), ".",
                     collapse = "")
  paste0(surname, ", ", initials)
}

# Author vector -> "Lynch, C.E.H., Casey, G., Suel, E., Dennett, A."
# Long lists are cut to the first six plus "…" plus Dennett if he'd
# otherwise be hidden.
cite_authors <- function(a, max_n = 6) {
  if (length(a) == 0) return("")
  cited <- vapply(a, cite_name, character(1), USE.NAMES = FALSE)
  if (length(cited) > max_n) {
    me <- grep("^Dennett,", cited, value = TRUE)
    head_n <- cited[seq_len(max_n)]
    tail_n <- if (length(me) && !me[1] %in% head_n) me[1] else character(0)
    cited <- c(head_n, "…", tail_n)
  }
  paste(cited, collapse = ", ")
}

# Strip HTML tags (ORCID titles sometimes carry <i>…</i>) and squash
# whitespace.
clean_text <- function(x) {
  trimws(gsub("\\s+", " ", gsub("<[^>]+>", "", x)))
}

# vitae escapes every LaTeX special in entry text and doesn't parse
# markdown, so *italics* print as literal asterisks. Instead, wrap italic
# text in these two markers (which vitae leaves alone) and pipe the
# finished entries through cv_italics() to turn them into \emph{}.
ITAL_OPEN  <- "⟪"
ITAL_CLOSE <- "⟫"

cv_italics <- function(entries) {
  tex <- as.character(knitr::knit_print(entries))
  knitr::asis_output(gsub(paste0(ITAL_OPEN, "(.*?)", ITAL_CLOSE),
                          "\\\\emph{\\1}", tex, perl = TRUE))
}

# "Title. Journal (italic). doi:…" — the second line of a CV / PDF entry.
cite_venue <- function(title, journal, doi) {
  title   <- clean_text(title)
  journal <- clean_text(ifelse(is.na(journal), "", journal))
  out <- ifelse(grepl("[.?!]$", title), title, paste0(title, "."))
  out <- ifelse(nzchar(journal),
                paste0(out, " ", ITAL_OPEN, journal, ITAL_CLOSE, "."), out)
  ifelse(!is.na(doi) & nzchar(doi), paste0(out, " doi:", doi), out)
}

# Lower-case alphanumerics only — used to match the same item across
# sources whose punctuation or dashes differ.
norm_key <- function(x, n = 40) {
  substr(gsub("[^a-z0-9]", "", tolower(x)), 1, n)
}
