### JSON Parsing ------------------------------------------------------------

get_files_by_hashtag <- function(hashtag, json_path) {
  cat(" | Getting files...")
  write(" | Getting files...", file = log_file, append = TRUE)
  # Get json files
  dir(
    path = json_path, full.names = TRUE,
    pattern = paste0(hashtag, "\\-")
  )
}

# take in json file and try parsing
parse_json <- function(file) {
  # FIXME: stops execution and does not print cond to log
  tryCatch(
    jsonlite::fromJSON(file, simplifyDataFrame = TRUE, flatten = TRUE),
    error = function(cond) {
      message(paste(file, "caused an error. See error message."))
      message(cond)

      write(paste(file, "caused an error:"), file = log_file, append = TRUE)
      # write(cond, file = log_file, append = TRUE) # FIXME

      return(NULL) # Choose a return value in case of error
    },
    warning = function(cond) {
      message(paste(file, "caused a warning. See warning:"))
      warning(cond)

      write(paste(file, "caused a warning:"), file = log_file, append = TRUE)
      write(cond, file = log_file, append = TRUE)

      return(NULL) # Choose a return value in case of warning
    }
  )
}


merge_queries <- function(dat) {
  # iterate over each API query response in input list and rbind the subtables together
  all <- list()
  all$main <- map_dfr(dat, ~ .x$data)
  all$users <- map_dfr(dat, ~ .x$includes$users)
  all$tweets <- map_dfr(dat, ~ .x$includes$tweets)
  all$media <- map_dfr(dat, ~ .x$includes$media)
  all$places <- map_dfr(dat, ~ .x$includes$places)
  # all$errors ?
  # all$polls ?
  return(all)
}

### Data Cleaning ------------------------------------------------------------

## Rename dataset with predefined namekeys for each subdataset
# set report_missing to TRUE to check for variables currently not in our preselection
rename_vars <- function(d, report_missing = FALSE) {
  main_names <- c(
    id = "status_id",
    author_id = "user_id",
    text = "text",
    created_at = "created_at",
    conversation_id = "conversation_id",
    lang = "lang",
    possibly_sensitive = "possibly_sensitive",
    referenced_tweets = "referenced_tweets",
    reply_settings = "reply_settings",
    context_annotations = "context_annotations",
    source = "source",
    in_reply_to_user_id = "in_reply_to_user_id",
    entities.mentions = "entities.mentions",
    entities.urls = "entities.urls",
    entities.hashtags = "entities.hashtags",
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
    protected = "user_protected",
    username = "user_name",
    pinned_tweet_id = "user_pinned_status_id",
    description = "user_description",
    verified = "user_is_verified",
    id = "user_id",
    created_at = "user_created_at",
    url = "user_url",
    location = "user_location",
    name = "name",
    profile_image_url = "user_profile_image",
    entities.url.urls = "entities.url.urls",
    entities.description.mentions = "entities.description.mentions",
    entities.description.urls = "entities.description.urls",
    entities.description.hashtags = "entities.description.hashtags",
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
    entities.urls = "entities.urls",
    entities.hashtags = "entities.hashtags",
    entities.mentions = "entities.mentions",
    entities.annotations = "ref_annotations",
    public_metrics.retweet_count = "ref_retweet_count",
    public_metrics.reply_count = "ref_reply_count",
    public_metrics.like_count = "ref_like_count",
    public_metrics.quote_count = "ref_quote_count",
    attachments.media_keys = "ref_media_id",
    attachments.poll_ids = "poll_ids",
    geo.place_id = "ref_place_id"
  )
  d$tweets <- plyr::rename(d$tweets, replace = tweets_names, warn_missing = report_missing)

  media_names <- c(
    height = "media_height",
    preview_image_url = "media_preview_url",
    media_key = "media_id",
    type = "media_type",
    width = "media_width",
    url = "media_url",
    duration_ms = "media_duration",
    public_metrics.view_count = "media_views"
  )
  d$media <- plyr::rename(d$media, replace = media_names, warn_missing = report_missing)

  places_names <- c(
    country_code = "place_country",
    country = "place_country_full",
    place_type = "place_type",
    id = "place_id",
    full_name = "place_full_name",
    name = "place_name",
    geo.type = "place_bbox_type",
    geo.bbox = "place_bbox"
  )
  d$places <- plyr::rename(d$places, replace = places_names, warn_missing = report_missing)
  return(d)
}

fill_missing_tibbles <- function(d) {
  # -> place_id / media_id and ref_status_id are also not in $main if not in the included data
  # nrow == 0 only works with tibbles
  if (nrow(d$tweets) == 0) {
    d$main$referenced_tweets <- list(NULL)
    d$tweets <- tibble(ref_status_id = NA_character_)
  }
  if (nrow(d$places) == 0) {
    d$main$place_id <- NA_character_
    d$places <- tibble(place_id = NA_character_)
  }
  if (nrow(d$media) == 0) {
    d$main$media_id <- list(NULL)
    # d$tweets$ref_media_id <- list(NULL) # FIXME
    d$media <- tibble(place_id = NA_character_)
  }
  return(d)
}


## Prepare Join // add media variables before removing them
prepare_join <- function(d) {
  # FIXME: not accurate
  d$main$ref_status_id <- map_chr(d$main$referenced_tweets, ~ ifelse(is.null(.x), NA, head(.x$id, 1)))
  # Add / Join Media so it can be removed afterwards
  # FIXME: Check for robustness
  # unnest media keys list, lookup media data and nest again in data frame
  d$main$referenced_media <- map(d$main$media_id, ~ map_dfr(.x, ~ d$media %>% filter(media_id == .x)))

  # FIXME: Weird recycling errors
  # Error: Assigned data `map(...)` must be compatible with existing data.
  # ℹ Row updates require a list value. Do you need `list()` or `as.list()`?
  # Unknown or uninitialised column: `ref_media_id
  # -> media can exist but no ref_media_id (needs to be checked for separately!)

  # d$tweets$ref_referenced_media <- map(d$tweets$ref_media_id, ~ map_dfr(.x, ~ d$media %>% filter(media_id == .x)))

  # reduce payload by removing duplicated media references in referenced_media dataframe
  # %>% distinct(media_id, .keep_all = TRUE)
  return(d)
}

# -> Identifier variables need to be distinct for correct joining!
drop_duplicates <- function(d) {
  d$main <- d$main %>% distinct(status_id, .keep_all = TRUE)
  d$users <- d$users %>% distinct(user_id, .keep_all = TRUE)
  d$tweets <- d$tweets %>% distinct(ref_status_id, .keep_all = TRUE)
  d$places <- d$places %>% distinct(place_id, .keep_all = TRUE)
  return(d)
}

join_tables <- function(d) {
  d$main %>%
    left_join(d$users, by = "user_id") %>%
    left_join(d$tweets, by = "ref_status_id") %>%
    left_join(d$places, by = "place_id")
  # media was nested before
}

# Reduce payload by removing obsolete variables
preselect_vars <- function(d) {
  d$main <- d$main %>% select(-contains("entities"))
  d$users <- d$users %>% select(-contains("entities"), -name, -contains("user_url"), -contains("user_protected"), -contains("user_profile_image"), -contains("user_pinned_status_id"))
  d$tweets <- d$tweets %>% select(-contains("entities"))
  d$media <- d$media %>% select(-contains("media_width"), -contains("media_height"))
  d$places <- d$places %>% select(-contains("place_country_full"))
  return(d)
}

order_vars <- function() {
 # TODO: enforce a more useful order of variables
}

