### Functions for matching replies with data and constructing chains ###

library(tidyverse)

# 1. is_head var (get all forward replies)
# 2. head_is_stable variable (= proxy var of how often reply chains are broken)
# -> Abschätzung
# 3. Reply exists in conversations data
# 4. Use alias reply to get sub-replies

# head_is_stable var:
# for all is_head == FALSE:
#   ref_replied_to_status_id lookup in all conversations (TRUE / FALSE)

# -> get a list of missing head's status_ids and use as proxy variable
