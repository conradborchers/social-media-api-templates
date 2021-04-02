### Omit Hashtags with less than n<100 original tweets ---------------------------
## Read in parsed hashtags
parsed <- readRDS(here::here("twitter-api", "download", "data", "all_hashtags_parsed.rds"))

# get list of original tweet count per hashtag
n_original <- map_dbl(parsed, ~ .x$main %>%
  select(id, text) %>%
  distinct(id, .keep_all = TRUE) %>%
  filter(!str_detect(text, "^RT @")) %>% # Filter out retweets
  nrow())

# create summary table
query_summary <- tibble(
  hashtag = hashtags,
  n_original = n_original,
  in_dataset = n_original >= 100
)

## Write query report (which hashtags dropped out)
# write_csv(query_summary, "twitter-api/queries/query_report.csv")

## Enforce threshold
d <- dat[query_summary$in_dataset]
# saveRDS(d, "twitter-api/download/hashtags_over_threshold.rds")


### Data Cleaning -------------------------------------------------------

library(tidyverse)

cat("Reading in parsed data over threshold...")
# d <- readRDS("twitter-api/download/hashtags_over_threshold.rds")
d <- readRDS("twitter-api/download/data/test_parsed_hashtags.rds")
d <- d[1:30]
n <- length(d)

# Get Functions
source(here::here("twitter-api", "download", "hashtag_merger_functions.R"))

# Iterate over all conversations in parsed data and clean + join + rbind
final <- imap_dfr(d, function(dat, index) {
  # using imap for progress indication
  cat("\014Processing", index, "/", n, "hashtags")
  dat %>%
    rename_vars() %>%
    preselect_vars() %>%
    fill_missing_tibbles() %>% # add placeholder foreign keys if subtables are empty
    drop_duplicates() %>% # remove duplicated primary and foreign keys in subtables
    wrangle_data() %>%
    join_tables()
})

cat("\nFinishing up dataset...")
final <- final %>%
  distinct(status_id, .keep_all = TRUE) %>%
  arrange(desc(created_at)) # timeline order (newest on top)


results_path <- paste0(here::here("twitter-api", "download", "data/"), "test_hashtags_cleaned.rds")
# results_path <- paste0(here::here("twitter-api", "download", "data/"), "data_hashtags_cleaned", Sys.Date(), ".rds")
cat("\nSaving Dataset to:\n", results_path, sep = "")
saveRDS(final, results_path)

usethis::ui_done("Finished!")
beepr::beep("mario")
