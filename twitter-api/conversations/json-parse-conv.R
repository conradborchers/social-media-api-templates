library(tidyverse)
library(jsonlite)

# rm(list = ls())

## Get all unique hashtags in json folder
conversations <- dir(path = here::here("scripts", "download", "json-conversations"), 
                     pattern = ".json") %>%
  str_extract_all("[:digit:]+(?=-)") %>%
  unlist() %>%
  unique()


get_files_by_conversation <- function(conversation) {
  dir(
    path = here::here("scripts", "download", "json-conversations"),
    full.names = TRUE, pattern = paste0(conversation, "\\-")
  )
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
collect_conversation <- function(conversation) {
  files <- get_files_by_conversation(conversation)
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
    cat("\014Read", i, "out of", length(files), "files for", conversation, "\n")
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
    saveRDS(paste0(here::here("scripts", "download", "parsed-conversations/"), conversation, ".rds"))
  # cat("\014Collected", conversation, "!\n")
}

index <- 19329
for (conv in conversations) {
  cat("\014Conversation", index, "out of", length(conversations), "\n")
  collect_conversation(conv)
  index <- index + 1
}
