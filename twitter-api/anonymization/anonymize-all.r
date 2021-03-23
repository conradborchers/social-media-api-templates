library(tidyverse)
library(hash)

# rm(list = ls())
# d <- readRDS("data-final-not-anonymized-2021-03-09.rds") # sample data




### Step two: Substitute @usernames with anonymous User IDs ----------------------------

user_pairs_main <- d$tweets %>%
  distinct(user_id, user_name) %>%
  rename(alias = user_name)

h <- hash(keys = user_pairs_main$alias, values = user_pairs_main$user_id)

mentions <- d$tweets$text %>%
  tolower() %>% # IMPORTANT to remember! (-> ignore_case = TRUE)
  str_extract_all("@[[:alnum:]_]+") %>%
  unlist() %>%
  unique() %>%
  str_remove_all("@")


## TODO: Add consistent, additional user alias to mentions without dictionary
# entries, to be discussed

missing_entries <- mentions[has.key(mentions, h) %>%
                              as.logical() %>%
                              `!`() %>% # negate()
                              which()]

missing_entries <- tibble(alias = missing_entries) %>%
  # added dash because its not allowed in Twitter's user namespace
  mutate(user_id = paste0("anon-", sample(50000001:100000000, length(missing_entries), replace = F))) %>%
  select(alias, user_id)

# Update hash
all <- rbind(user_pairs_main, missing_entries) # distinct removes one user_id, maybe an unwanted double?
h <- hash(keys = all$alias, values = all$user_id)

## ISSUE: Two users share the same user_id
# user_id  alias
# <chr>       <chr>
# 1 10463903 SelcukMerca
# 2 10463903 Seliboy

### Substitute @mentions
# LK: probably needs the @ as marker otherwise other text could get corrupted by greedy namematching in regex

## TODO: HOW TO QUICKLY ITERATE OVER TEXT AND LOOKUP @MENTIONS IN HASH,
## THEN SUBSTITUTE IN TEXT?

# LK: {Stringi} has the fastest text replacement function, but it is based on regex
# so we would still have to loop through the entire list, thus the hash table wouldn't offer any speed advantage quite the opposite actually
# -> the time-determining operation is not the lookup in the table, but the lookup in the text strings so we need to optimize for that somehow or just deal with a long runtime

# Speedup ideas:
# - input only text with mentions detected
# - make all lowercase
# - use lookahead on @ (check docs about fastest ways)
# - use "fixed" regex?!
# - let replacement run over atomic chr vector instead of col vector of df (-> add back to df afterwards)

library(stringi)

with_mention <- d$tweets %>%
  filter(str_detect(text, "@[[:alnum:]_]+")) %>%
  pull(text)

test <- list()
system.time(test$text <- stri_replace_all_regex(with_mention$text, all$user_id[1], all$alias[1]))

# WORK IN PROGRESS #

### Step 3: Define and remove sensitive variables ------------------------------

# TODO: CLEAN LINKS FROM TEXT ALREADY HERE?
# TODO: SELECT SENSITIVE VARS

d$tweets %>%
  select(-ref_referenced_tweets)


### Step 4: Save all ------------------------------------------------------------

filename <- paste0("data-final-anonymized-", Sys.Date(), ".rds")
saveRDS(d, filename)
