# library(tidyverse)
# 
# d <- readRDS("all_conversations_cleaned.rds")
# 
# d %>%  # there seems to be a couple of tweets with "in_reply_to_user" but not ref_status_id
#     filter(!(is.na(in_reply_to_user_id) | is.na(ref_status_id))) %>%
#     pull(ref_status_id) -> include # do not miss the reply heads
# 
# d2 <- d %>%
#     filter(
#            status_id %in% include | (!(is.na(in_reply_to_user_id) | is.na(ref_status_id)))
#            )
# 
# nrow(d2)  # 13k?
# 
# #> d$ref_conversation_id %>% unique %>% length  # how many of these conversations had 1 return only?
# #[1] 60448
# 
# # What if the conversation_id of a reply to user id with empty reference
# # should have the conversation ID as status ID reference?
# 
# d$ref_status_id[is.na(d$ref_status_id) & !is.na(d$in_reply_to_user_id)] <- 
#     d$conversation_id[is.na(d$ref_status_id) & !is.na(d$in_reply_to_user_id)]
# 
# d %>%  
#     filter(!(is.na(in_reply_to_user_id) | is.na(ref_status_id))) %>%
#     pull(ref_status_id) -> include 
# 
# d2 <- d %>%
#     filter(
#            status_id %in% include | (!(is.na(in_reply_to_user_id) | is.na(ref_status_id)))
#            )
# 
# nrow(d2)  # 15k, at least, but what else is in the downloaded conversations :D
#           # can each reference to tweets in "reference_conversation_id" be
#           # counted as a reply? and if yes, how would we know which status
#           # is replied to ... ? Do we need !(is.na(in_reply_to_user_id),
#           # i.e., are all ref_conversation_id replies?
# 
# d2 %>% select(status_id, user_id, ref_status_id, conversation_id, ref_conversation_id, in_reply_to_user_id) %>% 
#     arrange(conversation_id) %>% slice(4000:5000) %>% View()
# 
# d2$convo <- d2$ref_conversation_id
# d2$convo[is.na(d2$convo)] <- d2$conversation_id[is.na(d2$convo)]
# 
# d2 %>% select(created_at, status_id, user_id, ref_status_id, in_reply_to_user_id, convo) %>% 
#     arrange(convo, created_at) %>% View()
# 
# # in reply to user id is not correct or does not make sense?
# 
#### APPROACH with a TIBBLE of ALL STATUS IDs and CONVERSATION IDs SAMPLED
#### INCLUDING TIMESTAMPS TO ONLY OBTAIN FORWARD REPLIES

# Reference on replies: 
# https://cborchers.com/2021/03/23/notes-on-downloading-conversations-through-twitters-v2-api/
library(tidyverse)
d <- readRDS("all_conversations_cleaned.rds")
r <- readRDS("reply-reference.rds")

greenlight <- r$status_id
found <- c()
i <- 1

target <- r$status_id # status_ids of all intially downloaded tweets (hashtag search) with n>0 replies
found <- d$status_id[d$ref_status_id %in% target] # initial search, d are downloaded conversation tweets

while (length(found)>0) {
    cat("\014Found",length(found),"replies in layer",i,"\n")
    greenlight <- c(greenlight, found)
    # Search in next layer
    target <- found
    found <- d$status_id[d$ref_status_id %in% target]
    i<-i+1
}

d <- d %>% 
    filter(status_id %in% greenlight) %>%  # filter only forward replies
    mutate(is_forward_reply = TRUE)

saveRDS(d, "added-forward-replies-final.rds")

# TODO: 
# a) check if code make sense, e.g. check in merged data set (see b)) if
#    is_forward_reply is reasonably connected to tweets in main data set
# b) add added-forward-replies-final.rds to main data set, equalize variables
# c) anonymize whole data set with anonymizing script
# d) clean repo and workflow

