### Script for complete Conversations Parsing + Cleaning ###

library(tidyverse)

# Manually Fixed: "1278675494813216768"

# Get all unique conversations in folder
conversations <- dir(path = here::here("scripts", "download", "json-conversations"), pattern = ".json") %>%
  str_extract_all("[:digit:]+(?=-)") %>%
  unlist() %>%
  unique()

# Get all corresponding files per conversation
get_files_by_conversation <- function(con) {
  cat("\014Getting conversation:", con)
  dir(path = here::here("scripts", "download", "json-conversations"), full.names = TRUE, pattern = paste0(con, "\\-"))
}

# Robust parsing method, logs errors to /conversations_log.txt
get_json <- function(file) {
  tryCatch(
    expr = jsonlite::fromJSON(file, simplifyDataFrame = TRUE, flatten = TRUE),
    error = function(cond) {
      message(paste("There seems to be an error with conversation:", file))
      message("Here's the original error message:")
      message(cond)

      write(paste("Error with", file), file = "conversations_log.txt", append = TRUE)
      write(cond, file = "conversations_log.txt", append = TRUE)
      # Choose a return value in case of error
      return(NA)
    },
    warning = function(cond) {
      message(paste("Conversation caused a warning:", file))
      message("Here's the original warning message:")
      message(cond)

      write(paste("Warning with", file), file = "conversations_log.txt", append = TRUE)
      write(cond, file = "conversations_log.txt", append = TRUE)
      # Choose a return value in case of warning
      return(NA)
    }
  )
}

# FIXME: Introduction of Joining errors?
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


## TODO: Add Index with imap
# For each conversation
all <- map(
  conversations,
  # get all corresponding json files
  ~ get_files_by_conversation(.x) %>%
    # convert these json files to lists and return a list of all files per conversation
    map(~ get_json(.x)) %>%
    # Merge the different files to one list per conversation
    merge_queries()
)

# saveRDS(all, "all_conversations_parsed.rds")

### Data Cleaning -------------------------------------------------------

# Get Functions
source(here::here("twitter-api", "conversations", "merger_functions.R"))

cat("Reading in parsed data...")
all <- readRDS(here::here("twitter-api","conversations","all_conversations_parsed.rds"))

# all <- d[1:10]
n <- length(all)

# Iterate over all conversations in parsed data and clean + join + rbind
final <- imap_dfr(all, function(dat, index) {
  # imap for progress indication
  cat("\014Processing", index, "/", n, "conversations")
  dat %>%
    rename_vars() %>%
    preselect_vars() %>%
    fill_missing_tibbles() %>%
    prepare_join() %>%
    drop_duplicates() %>%
    join_tables()
})

cat("Finishing up...")
# final <- final %>%
  ### FIXME: THIS distinct() COULD BE PROBLEMATIC, NEED TO CHECK MORE
  distinct(status_id, .keep_all = TRUE) %>%
  arrange(created_at) # not formated yet

cat("Saving Dataset...")
saveRDS(final, here::here("twitter-api","conversations","all_conversations_raw.rds"))

# TODO: Paper Vars Selection here?
