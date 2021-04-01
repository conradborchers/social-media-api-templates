### Parse JSON files ###

library(tidyverse)

# log_file <- file(paste0(here::here("twitter-api", "download"), "/parsing_", Sys.time(), ".log"), open = "a")

source(here::here("twitter-api", "download", "cleaning_functions.R"))

hashtags <- dir(path = here::here("twitter-api", "download", "json"), pattern = ".json") %>%
  str_extract_all("#[[:alnum:]_]+") %>%
  unlist() %>%
  unique()

n <- length(hashtags)
all <- imap(hashtags, function(hashtag, index) {
  cat("\014", index, "/", n, "| Parsing", hashtag)
  cat("\n", index, "/", n, "| Parsing", hashtag, file = "parsing.log", append = TRUE)
  get_files_by_hashtag(hashtag) %>%
    # convert these json files to lists and return a list of all files per hashtag
    map(~ get_json(.x)) %>%
    # Merge the different files to one list element per hashtag
    merge_queries()
})

# saveRDS(all, here::here("twitter-api", "download", "all_hashtags_parsed.rds"))


### Omit Hashtags with less than n<100 original tweets ---------------------------
dat <- readRDS(here::here("twitter-api", "download", "all_hashtags_parsed.rds"))


n_original <- map_dbl(dat, ~ .x$main %>%
  select(id, text) %>%
  distinct(id, .keep_all = TRUE) %>%
  filter(!str_detect(text, "^RT @")) %>% # Filter out retweets
  nrow())

query_summary <- tibble(
  hashtag = hashtags,
  n_original = n_original,
  in_dataset = n_original >= 100
)

# write_csv(query_summary, "twitter-api/queries/query_report.csv")

# Enforce threshold
d <- dat[query_summary$in_dataset]
# saveRDS(d, "twitter-api/download/hashtags_over_threshold.rds")

### Data Cleaning -------------------------------------------------------

library(tidyverse)
# Get Functions
source(here::here("twitter-api", "download", "clean_functions.R"))

cat("Reading in parsed data...")
d <- readRDS("twitter-api/download/hashtags_over_threshold.rds")

n <- length(d)

# Iterate over all conversations in parsed data and clean + join + rbind
final <- imap_dfr(d, function(dat, index) {
  # imap for progress indication
  cat("\014Processing", index, "/", n, "hashtags")
  dat %>%
    rename_vars() %>%
    preselect_vars() %>%
    fill_missing_tibbles() %>%
    prepare_join() %>%
    drop_duplicates() %>%
    join_tables()
})

cat("\nFinishing up...")
final <- final %>%
  distinct(status_id, .keep_all = TRUE) %>%
  arrange(desc(created_at))


cat("\nSaving Dataset...")
saveRDS(final, here::here("twitter-api", "download", "data_hashtags_cleaned.rds"))

# TODO: Add beepr::
