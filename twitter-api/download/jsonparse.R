library(dplyr)
library(purrr)
library(readr)
library(stringr)
library(jsonlite)

# setwd("scripts/download/")
# rm(list = ls())

## Get all unique hashtags in json folder
hashtags <- dir(path = "json") %>%
  str_extract_all("#[[:alnum:]_]+") %>%
  unlist() %>%
  unique()


get_files_by_hashtag <- function(hashtag) {
  dir(path = "json", full.names = TRUE, pattern = paste0(hashtag, "\\-"))
}

# Flatten the nested structure if not empty
flatten_if_not_null <- function(l) {
  if (is.null(l)) {
    return(NULL)
  } else {
    return(jsonlite::flatten(l, recursive = TRUE))
  }
}

# Read in Files, flatten data, combine as list and write to file
collect_hashtag <- function(hashtag) {
  files <- get_files_by_hashtag(hashtag)
  main <- list()
  users <- list()
  tweets <- list()
  media <- list()
  places <- list()
  i <- 1

  for (file in files) {
    d <- fromJSON(file)

    main[[i]] <- flatten_if_not_null(d$data) %>%
      (function(x) {
        if (is.null(x)) {
          return(NULL)
        } else {
          # use `contains` to shield against not existing variables
          return(x %>%
            select(
              id, created_at, author_id, text, lang, contains("public_metrics"), contains("referenced_tweets"),
              contains("media_keys"), contains("place_id"), contains("conversation_id"),
              contains("in_reply_to_user_id"), contains("source"), contains("possibly_sensitive"),
              contains("reply_settings"), contains("annotations")
            ))
        }
      })

    users[[i]] <- flatten_if_not_null(d$includes$users) %>%
      (function(x) {
        if (is.null(x)) {
          return(NULL)
        } else {
          return(x %>% select(
            id, created_at, description, contains("username"), contains("verified"),
            contains("location"), contains("public_metrics")
          ))
        }
      })
    tweets[[i]] <- flatten_if_not_null(d$includes$tweets) %>%
      (function(x) {
        if (is.null(x)) {
          return(NULL)
        } else {
          return(x %>% select(
            id, created_at, contains("author_id"), text, contains("lang"),
            contains("public_metrics"), contains("conversation_id"),
            contains("source"), contains("possibly_sensitive"),
            contains("reply_settings"), contains("annotations"),
            contains("in_reply_to_user_id"), contains("referenced_tweets"),
            contains("place_id"), contains("media_keys")
          ))
        }
      })

    media[[i]] <- flatten_if_not_null(d$includes$media) %>%
      (function(x) {
        if (is.null(x)) {
          return(NULL)
        } else {
          return(x %>% select(
            contains("media_key"), contains("type"),
            contains("url"), contains("preview_image_url"),
            contains("public_metrics"),
            contains("duration")
          ))
        }
      })

    places[[i]] <- flatten_if_not_null(d$includes$places) %>%
      (function(x) {
        if (is.null(x)) {
          return(NULL)
        } else {
          return(x %>% select(
            contains("id"), contains("place_type"), contains("country_code"),
            contains("full_name"), contains("name"),
            contains("bbox")
          ))
        }
      })


    ## Print parsing status
    cat("\014Read", i, "out of", length(files), "files for", hashtag, "\n")
    i <- i + 1
  }

  ## Save Data
  list(
    main = plyr::rbind.fill(main) %>% tibble(),
    users = plyr::rbind.fill(users) %>% tibble(),
    tweets = plyr::rbind.fill(tweets) %>% tibble(),
    media = plyr::rbind.fill(media) %>% tibble(),
    places = plyr::rbind.fill(places) %>% tibble()
  ) %>%
    (function(x) {
      has_enough_if_not_has_n <- x$main %>%
        select(id, text) %>%
        distinct(id, .keep_all = TRUE) %>%
        filter(!str_detect(text, "^RT @")) %>% # Filter out retweets
        (function(d) {
          if (nrow(d) >= 100) {
            return(TRUE)
          } else {
            return(nrow(d))
          }
        })

      ## Save to RDS in parsed/ folder if over threshold
      if (isTRUE(has_enough_if_not_has_n)) {
        saveRDS(x, paste0("parsed/", hashtag, ".rds"))
        cat("\014Collected", hashtag, "!\n")
      } else {
        cat("\014Collected", hashtag, "but it had less than 100 unique tweets and was not saved...\n")
        system(paste0("echo \"", hashtag, ": ", has_enough_if_not_has_n, "\" >> excluded.txt"))
      }
    })
}

system("echo Overview-Excluded-Hashtags: > excluded.txt")
for (hashtag in hashtags) collect_hashtag(hashtag)
