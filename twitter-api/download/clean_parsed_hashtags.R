### Omit Hashtags with less than n<100 original tweets ---------------------------
## Read in parsed hashtags
dat <- readRDS(here::here("twitter-api", "download", "all_hashtags_parsed.rds"))

# get list of original tweet count per hashtag
n_original <- map_dbl(dat, ~ .x$main %>%
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
# Get Functions
source(here::here("twitter-api", "download", "hashtag_merger_functions.R"))

cat("Reading in parsed data over threshold...")
d <- readRDS("twitter-api/download/hashtags_over_threshold.rds")
n <- length(d)

# Iterate over all conversations in parsed data and clean + join + rbind
final <- imap_dfr(d, function(dat, index) {
  # using imap for progress indication
  cat("\014Processing", index, "/", n, "hashtags")
  dat %>%
    rename_vars() %>%
    preselect_vars() %>%
    fill_missing_tibbles() %>%
    prepare_join() %>%
    drop_duplicates() %>%
    join_tables()
})

cat("\nFinishing up dataset...")
final <- final %>%
  distinct(status_id, .keep_all = TRUE) %>%
  arrange(desc(created_at))


results_path <- paste0(here::here("twitter-api", "download/"), "data_hashtags_cleaned", Sys.Date(), ".rds")
cat("\nSaving Dataset to:", results_path)
saveRDS(final, results_path)

usethis::ui_done("Finished!")
beepr::beep("mario")
