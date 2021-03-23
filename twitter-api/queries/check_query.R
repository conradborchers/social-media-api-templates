### Compare old queries with newest ###

library(tidyverse)
library(googlesheets4)

## Get old query list
down <- read_sheet("URL")


## Get newest query list
query <- read_lines("queries.txt") %>%
  as.data.frame() %>%
  setNames("hashtag")

## Show hashtags not included in newest query list
missing <- anti_join(down, query)

## Export
missing <- missing %>% mutate(n = n %>% replace_na(0))
# write_sheet(missing, "URL", "Not included hashtags")
