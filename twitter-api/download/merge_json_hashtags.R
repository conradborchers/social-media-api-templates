### Parse JSON files ###

library(tidyverse)

log_file <- paste0(here::here("twitter-api", "download/"), "json_parsing_", Sys.Date(), ".log")
file.remove(log_file) # clear existing log file


# Load Merger functions
source(here::here("twitter-api", "download", "hashtag_merger_functions.R"))

# Read in json files
json_path <- here::here("twitter-api", "download", "json")
hashtags <- dir(path = json_path, pattern = ".json") %>%
  str_extract_all("#[[:alnum:]_]+") %>% # get names of downloaded hashtags
  unlist() %>%
  unique()

n <- length(hashtags)
# Parse and merger json files per hashtag
all <- imap(hashtags, function(hashtag, index) {
  cat("\014", index, "/", n, "| Parsing", hashtag) # write to console
  cat(index, "/", n, "| Parsing", hashtag, file = log_file, append = TRUE) # write to log
  # get all json query responses for each hashtag
  get_files_by_hashtag(hashtag, json_path) %>%
    # parse these json files and return a list of all files per hashtag
    map(~ parse_json(.x)) %>%
    # Merge the different files to one list element per hashtag
    merge_queries()
})

## Save all parsed hashtags
# saveRDS(all, here::here("twitter-api", "download", "all_hashtags_parsed.rds"))
