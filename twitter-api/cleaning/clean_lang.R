# migrated from old script for future use
# LK TODO: implement new language selection criteria (see notes) / not threshold
check_language <- function(dat, threshold = 0.75) {
  n_de <- dat %>%
    group_by(lang) %>%
    count() %>%
    filter(lang == "de") %>%
    ## return 0 if there is no "de" at all in hashtag dataset (edge case)
    # TODO: try to do with if_else or tryCatch instead #DRY
    (function(x) {
      if (nrow(x) == 0) {
        return(0)
      } else {
        return(x %>% pull(n))
      }
    })
  # Maybe ignore "und" here in Grundgesamtheit?
  lang_ratio <- n_de / nrow(dat)

  if (lang_ratio >= threshold) {
    return(TRUE)
  } else {
    return(FALSE)
  }
  # TODO: Report Omitted Hashtags?
}
