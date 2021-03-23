### Explore Conversations ###

library(tidyverse)
library(googlesheets4)
library(jsonlite)

json <- fromJSON("scripts/download/json-conversations/111501238356553729-1.json")
                            
paths <- dir(path = "scripts/download/json-conversations/", full.names = TRUE)


map(paths[1:100], ~map(fromJSON(.x), names))

dat <- json$data %>% flatten(recursive = TRUE)

  
  

glimpse(json)
