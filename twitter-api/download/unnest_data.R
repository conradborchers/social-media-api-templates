### Unnest referenced_tweets and split variables in type of reference ###

library(tidyverse)

final <- readRDS("twitter-api/download/data/test_hashtags_cleaned.rds")

### manipulate test data for multi-references
# test <- final[10, ]
final$referenced_tweets[[10]] <- bind_rows(final$referenced_tweets[[10]], final$referenced_tweets[[10]])
final$referenced_tweets[[10]][1, 1] <- "replied_to" # set copy to ref_type replied_to

# final$referenced_tweets[[10]] %>% View()

### Split ref variables by ref_type ------------------------------------------------

# FIXME: mappify after debugging
# Note: NULL values (e.g. in ref_media_id) are automatically omited #FIXME?
for (i in seq_len(nrow(final))) {
  print(i)
  final$referenced_tweets_typed[[i]] <- final$referenced_tweets[[i]] %>%
    # select(-contains("annotations")) %>% # changed globally
    pmap_dfc(function(...) {
    ref <- tibble(...) # FIXME: does currently not work with ref_annotations because of subnesting (explore and come back!)
    clean <- ref %>%
      rename_with(~ str_replace_all(.x, pattern = "ref_", replacement = glue::glue("ref_{ref$type}_"))) %>%
      select(-id, -type)
      # FIXME: rename id in join function from the beginning and dont remove it here

    return(clean)
  })
}

# Check data:
View(final[, c("referenced_tweets", "referenced_tweets_typed")])


### Unnest Ref Data -------------------------------------------------------

# unnest references vars to top level data frame
# Note: removes "referenced_tweets"
final <- final %>% unnest_wider(referenced_tweets_typed,
                                names_repair = "universal") # FIXME: weird join errors with coordinates (check if where from)


### FIXME: Warning
# In stri_replace_all_regex(string, pattern, fix_replacement(replacement),  ... :
# longer object length is not a multiple of shorter object length
