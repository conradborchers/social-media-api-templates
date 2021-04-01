## FIXME: Can remove / clean old code?

# library(dplyr)
# library(purrr)
# library(readr)
# library(stringr)
# library(jsonlite)
#
# # rm(list = ls())
# # setwd("twitter-api/download/")
# # -> setwd to download folder with /json data folder
#
# ### First Approach ----------------------------------------------------------------
# ### Only select conversations featured in more than one status
#
# ## Get all json files with full paths
# fs <- dir(path = "json", full.names = TRUE)
#
# collect_conversations <- function(files) {
#   conversations <- list()
#   i <- 1
#   for (file in files) {
#     d <- fromJSON(file)
#
#     conversations[[i]] <- data.frame(
#       status_id = d$data$id,
#       conversation_id = d$data$conversation_id
#     )
#
#     ## Print parsing status
#     cat("\014Read", i, "out of", length(files), "files\n")
#     i <- i + 1
#   }
#
#   ## Combine all conversation IDs into one object, keep unique statuses
#   return(do.call(rbind, conversations) %>%
#     tibble() %>%
#     distinct(status_id, .keep_all = TRUE))
# }
#
# ## Get conversation IDs to file for download
# conversations <- collect_conversations(fs)
#
# # Only select conversations featured in more than one status
# conversations_2 <- conversations %>%
#   group_by(conversation_id) %>%
#   count() %>%
#   filter(n > 1) %>%
#   pull(conversation_id)
#
# # Write conversation_id to file
# sink("cids.txt")
# for (cid in conversations_2) cat(cid, "\n")
# sink()
#
# ### Approach two: Conversations with at least 1 reply ----------------------------
# ###               Get replies in forward search
#
# library(dplyr)
# library(purrr)
# library(readr)
# library(stringr)
# library(jsonlite)
#
# rm(list = ls())
#
# ## Get all json files with full paths
# fs <- dir(path = "json", full.names = TRUE)
#
# collect_conversations <- function(files) {
#   conversations <- list()
#   i <- 1
#   for (file in files) {
#     d <- fromJSON(file)
#
#     conversations[[i]] <- data.frame(
#       reply_count = d$data$public_metrics$reply_count,
#       conversation_id = d$data$conversation_id
#     ) %>%
#       filter(reply_count > 0) %>%
#       pull(conversation_id)
#
#     ## Print parsing status
#     cat("\014Read", i, "out of", length(files), "files\n")
#     i <- i + 1
#   }
#
#   ## Combine all conversation IDs into one object, keep unique statuses
#   return(do.call(c, conversations)
#   %>% unique())
# }
#
# ## Get conversation IDs to file for download
# conversations <- collect_conversations(fs)
#
# # Write conversation_id to file
# sink("cids-forward.txt")
# for (cid in conversations) cat(cid, "\n")
# sink()
#
#
# ### FINAL? ----------------------------------------------------------------
# # Addendum, TODO: include in main for loop above
# # Need for reference of sampled status IDs and corresponding
# # conversation IDs in order to finalize clean-conversations.rds
#
# library(dplyr)
# library(purrr)
# library(readr)
# library(stringr)
# library(jsonlite)
#
# # rm(list = ls())
# # setwd("twitter-api/download/")
#
# ## Get all json files with full paths
# fs <- dir(path = "json", full.names = TRUE, pattern = "*.json")
#
# collect_conversations <- function(files) {
#   conversations <- list()
#   i <- 1
#   for (file in files) {
#     d <- fromJSON(file)
#
#     conversations[[i]] <- data.frame(
#       status_id = d$data$id,
#       created_at = d$data$created_at,
#       reply_count = d$data$public_metrics$reply_count,
#       conversation_id = d$data$conversation_id
#     ) %>%
#       filter(reply_count > 0) %>%
#       select(-reply_count)
#
#     ## Print parsing status
#     cat("\014Read", i, "out of", length(files), "files\n")
#     i <- i + 1
#   }
#
#   ## Combine all conversation IDs into one object, keep unique statuses
#   return(do.call(rbind, conversations) %>%
#     distinct(status_id, .keep_all = TRUE))
# }
#
# d <- collect_conversations(fs)
#
# saveRDS(d, "reply-reference.rds")


### New Extraction from parsed Data ------------------------------------------------------
# Notes
# - status_id should be unique
# - conversation_id should not be unique in reference list but in download lists

library(tidyverse)

# Read in all tweets
dat <- readRDS(here::here("twitter-api", "download", "data_hashtags_cleaned.rds"))

conversations <- tibble(
  status_id = dat$tweets$status_id,
  created_at = dat$tweets$created_at,
  reply_count = dat$tweets$reply_count,
  conversation_id = dat$tweets$conversation_id
  # is_head = dat$is_head
)

conversations <- conversations %>%
  distinct(status_id, .keep_all = TRUE) %>% # already distinct status_ids but JIC
  filter(reply_count > 0)

# is_head indicates if status is a conversation starter
# TODO: add variable even earlier to entire dataset?
conversations <- conversations %>%
  mutate(is_head = status_id == conversation_id)

# small but important detail
# FIXME: for the download file yes, but I don't think this is right for the inspection of reply structures
# there can be multiple tweets in one conversation without the head being part of our sample (as discussed in meeting)
conversations <- conversations %>%
  distinct(conversation_id, .keep_all = TRUE)

# saveRDS(conversations, here::here("twitter-api", "conversations", "reply-reference.rds"))

## TODO: Migrate generation of cid download files to here
