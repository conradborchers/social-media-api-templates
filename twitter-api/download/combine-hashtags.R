library(tidyverse)
library(here)

rm(list = ls())

## Rename dataset with predefined namekeys for each subdataset
# set report_missing to TRUE to check for variables currently not in our preselection
rename_vars <- function(d, report_missing = FALSE) {
  main_names <- c(
    possibly_sensitive = "possibly_sensitive",
    author_id = "user_id",
    id = "status_id",
    lang = "lang",
    referenced_tweets = "referenced_tweets",
    reply_settings = "reply_settings",
    context_annotations = "context_annotations",
    source = "source",
    text = "text",
    created_at = "created_at",
    conversation_id = "conversation_id",
    in_reply_to_user_id = "in_reply_to_user_id",
    entities.mentions = "",
    entities.urls = "",
    entities.hashtags = "",
    entities.annotations = "annotations",
    public_metrics.retweet_count = "retweet_count",
    public_metrics.reply_count = "reply_count",
    public_metrics.like_count = "like_count",
    public_metrics.quote_count = "quote_count",
    attachments.media_keys = "media_id",
    geo.place_id = "place_id"
  )
  d$main <- plyr::rename(d$main, replace = main_names, warn_missing = report_missing)

  users_names <- c(
    protected = "",
    username = "user_name",
    pinned_tweet_id = "",
    description = "user_description",
    verified = "user_is_verified",
    id = "user_id",
    created_at = "user_created_at",
    url = "",
    location = "user_location",
    name = "",
    profile_image_url = "",
    entities.url.urls = "",
    entities.description.mentions = "",
    entities.description.urls = "",
    entities.description.hashtags = "",
    public_metrics.followers_count = "followers_count",
    public_metrics.following_count = "following_count",
    public_metrics.tweet_count = "tweet_count",
    public_metrics.listed_count = "listed_count"
  )
  d$users <- plyr::rename(d$users, replace = users_names, warn_missing = report_missing)

  tweets_names <- c(
    possibly_sensitive = "ref_possibly_sensitive",
    author_id = "ref_user_id",
    id = "ref_status_id",
    lang = "ref_lang",
    reply_settings = "ref_reply_settings",
    context_annotations = "ref_context_annotations",
    source = "ref_source",
    text = "ref_text",
    created_at = "ref_created_at",
    conversation_id = "ref_conversation_id",
    in_reply_to_user_id = "ref_in_reply_to_user_id",
    referenced_tweets = "ref_referenced_tweets",
    entities.urls = "",
    entities.hashtags = "",
    entities.mentions = "",
    entities.annotations = "ref_annotations",
    public_metrics.retweet_count = "ref_retweet_count",
    public_metrics.reply_count = "ref_reply_count",
    public_metrics.like_count = "ref_like_count",
    public_metrics.quote_count = "ref_quote_count",
    attachments.media_keys = "ref_media_id",
    attachments.poll_ids = "",
    geo.place_id = "ref_place_id"
  )
  d$tweets <- plyr::rename(d$tweets, replace = tweets_names, warn_missing = report_missing)

  media_names <- c(
    height = "",
    preview_image_url = "media_preview_url",
    media_key = "media_id",
    type = "media_type",
    width = "",
    url = "media_url",
    duration_ms = "media_duration",
    public_metrics.view_count = "media_views"
  )
  d$media <- plyr::rename(d$media, replace = media_names, warn_missing = report_missing)

  places_names <- c(
    country_code = "place_country",
    country = "",
    place_type = "place_type",
    id = "place_id",
    full_name = "place_full_name",
    name = "place_name",
    geo.type = "",
    geo.bbox = "place_bbox"
  )
  d$places <- plyr::rename(d$places, replace = places_names, warn_missing = report_missing)
  return(d)
}

fill_missing_tibbles <- function(d) {
  # -> place_id / media_id and ref_status_id are also not in $main if not in the included data
  if (nrow(d$tweets) == 0) {
    d$tweets <- tibble(ref_status_id = NA_character_)
    d$main$referenced_tweets <- list(NULL)
  }
  if (nrow(d$places) == 0) {
    d$places <- tibble(place_id = NA_character_)
    d$main$place_id <- NA_character_
  }
  ## TODO: Add Media?
  return(d)
}

prepare_join <- function(d) {
  ## Extract ref_status_id from referenced_tweets and fill up with NA if null
  # Can there be multiple referenced tweets? How to handle?
  # CB: In the NGSSchat dataset we had around .001% of tweets with n>1
  # referenced tweets. I would say you take head(1) and ignore these cases
  d$main$ref_status_id <- map_chr(d$main$referenced_tweets, ~ ifelse(is.null(.x), NA, head(.x$id, 1)))

  ## Unnest media_id
  # FIXME: More than one media possible, needs to be a vector / list!!
  # Problem: How to join over multiple media points in one row?
  # Example Tweet: https://twitter.com/kinexon/status/1042777098333638657
  # Possible Solution: pick only one?
  # d$main$media_id <- map_chr(d$main$media_id, ~ ifelse(is.null(.x), NA, pluck(.x, 1)))
  
  # CB: How about storing them in a separate DF and joining them in the
  # targets pipeline on demand. You can not really get a one size fits all tidy tibble here IMO

  # LK: Works fine, alternatively join as nested tibble (can be done at any point though):
  # d$main$referenced_media <- map(d$main$media_id, ~ map_dfr(.x, ~ d$media %>% filter(media_id == .x)))

  return(d)
}

drop_duplicates <- function(d) {
  # -> Identifier variables need to be distinct for a correct join!
  d$main <- d$main %>% distinct(status_id, .keep_all = TRUE)
  d$users <- d$users %>% distinct(user_id, .keep_all = TRUE)
  d$tweets <- d$tweets %>% distinct(ref_status_id, .keep_all = TRUE)
  d$places <- d$places %>% distinct(place_id, .keep_all = TRUE)
  return(d)
}

join_tables <- function(d) {
  return(
    list(
      tweets = d$main %>%
        left_join(d$users, by = "user_id") %>%
        left_join(d$tweets, by = "ref_status_id") %>%
        left_join(d$places, by = "place_id"),
      media = d$media
    )
  )
}

## Remove Duplicates from joined data
no_duplicates <- function(d) {
  return(
    list(
      tweets = d$tweets %>% distinct(status_id, .keep_all = TRUE),
      media = d$media
    )
  )
}

## Checks if hashtag passes language threshold
# Only run after Joining / removing duplicates
# TODO: Discuss Threshold in upcoming Meeting
# Problems:
# - in Spanish subject hashtags there could be a lot of Spanish tweets from German teachers...
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

filter_at_lang_threshold <- function(d) {
  return(
    list(
      tweets = d$tweets %>% filter(check_language(.)),
      media = d$media
    )
  )
}


### Data Joining -----------------------------------------------------------------

#### Option a) Merge directly ####
merge_clean_hashtags <- function(hashtag) {
  cat("\014Processing", hashtag, "\n")
  readRDS(here::here("scripts", "download", "parsed", hashtag)) %>%
    rename_vars() %>%
    fill_missing_tibbles() %>%
    prepare_join() %>%
    drop_duplicates() %>%
    join_tables() %>%
    no_duplicates() %>% # (function(x)return(x))
    filter_at_lang_threshold()
}

paths <- dir(path = here::here("scripts", "download", "parsed"), pattern = "#[[:alnum:]_]+.rds")
# paths <- sample(paths, 30, replace=F) #testing

final <- map(paths, merge_clean_hashtags)

document_lang_filtered_hashtags <- function(d) {
  sink("filtered-out-by-lang-threshold.txt")
  for (file in paths[which(map_lgl(d, ~nrow(.x$tweets) == 0))]) {
    cat(file, "\n")
  }
  sink()
  return(d)
}

final_touches <- function(d) {
  # Merge all list elements for tweets and media
  d <- list(
    tweets = map_dfr(d, "tweets"),
    # Handle empty media return value
    media = bind_rows(map(d, "media")[map_lgl(d, ~nrow(.x$media) > 0)])
  )
  # Drop Duplicates across hashtags and sort by created_at
  d$tweets <- d$tweets %>%
    distinct(status_id, .keep_all = TRUE) %>%
    arrange(created_at)
  
  d$media <- d$media %>% distinct(media_id, .keep_all = TRUE)
  return(d)
}

export <- final %>%
  document_lang_filtered_hashtags() %>%
  final_touches()

filename <- paste0("data-final-not-anonymized-", Sys.Date(), ".rds")
export %>% saveRDS(filename)
