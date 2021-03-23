library(reticulate)
library(tidyverse)

d <- readRDS("./scripts/download/data-final-not-anonymized-2021-03-09.rds")

# Step zero (outsource to parsing script?): Split and omit references tweets variable

# We still lack a ref_ref_status_id, ref_type and ref_ref_type variable?!

d$tweets$ref_status_type <- map(d$tweets$referenced_tweets, 1) %>% as.character() %>% (function(x){x[x=="NULL"]<-NA;return(x)})
d$tweets <- d$tweets %>% select(-referenced_tweets)

d$tweets$ref_ref_status_type <- map(d$tweets$ref_referenced_tweets, 1) %>% as.character() %>% (function(x){x[x=="NULL"]<-NA;return(x)})
d$tweets$ref_ref_status_id <- map(d$tweets$ref_referenced_tweets, 2) %>% as.character() %>% (function(x){x[x=="NULL"]<-NA;return(x)})
d$tweets <- d$tweets %>% select(-ref_referenced_tweets)

# Step one: Anonymize Status IDs and User IDs -----------------------------------

all_status_ids <- c(
  d$tweets$status_id,
  d$tweets$ref_status_id,
  d$tweets$ref_ref_status_id
) %>%
  unique() %>%
  na.omit() %>%
  as.character()  # remove na.omit class

all_user_ids <- c(
  d$tweets$user_id,
  d$tweets$ref_user_id,
  d$tweets$in_reply_to_user_id,
  d$tweets$ref_in_reply_to_user_id
) %>%
  unique() %>%
  na.omit() %>%
  as.character()

set.seed(42) # for synchronous testing
random_status_ids <- sample(1:50000000, length(all_status_ids), replace = FALSE) %>% as.character()
random_user_ids <- sample(1:50000000, length(all_user_ids), replace = FALSE) %>% as.character()

sids <- tibble(
  old = all_status_ids,
  new = random_status_ids
)

uids <- tibble(
  old = all_user_ids,
  new = random_user_ids
)

saveRDS(sids, "sids_crowsswalk.rds")
saveRDS(uids, "uids_crosswalk.rds")
rm(all_status_ids, all_user_ids, random_status_ids, random_user_ids)


### Overwrite old status_ids -------------------------------------------------------

# Overwrite $status_id with key values
sids <- sids %>% rename(status_id = old)
d$tweets <- d$tweets %>%
  left_join(sids, by = "status_id", na_matches = "never") %>%
  mutate(status_id = new) %>%
  select(-new)
sids <- sids %>% rename(old = status_id)


# Overwrite $ref_status_id with key values
sids <- sids %>% rename(ref_status_id = old)
d$tweets <- d$tweets %>%
  left_join(sids, by = "ref_status_id", na_matches = "never") %>%
  mutate(ref_status_id = new) %>%
  select(-new)
sids <- sids %>% rename(old = ref_status_id)

# Overwrite $ref_ref_status_id with key values
sids <- sids %>% rename(ref_ref_status_id = old)
d$tweets <- d$tweets %>%
  left_join(sids, by = "ref_ref_status_id", na_matches = "never") %>%
  mutate(ref_ref_status_id = new) %>%
  select(-new)
sids <- sids %>% rename(old = ref_ref_status_id)


# Overwrite $user_id with key values
uids <- uids %>% rename(user_id = old)
d$tweets <- d$tweets %>%
  left_join(uids, by = "user_id", na_matches = "never") %>%
  mutate(user_id = new) %>%
  select(-new)
uids <- uids %>% rename(old = user_id)


# Overwrite $ref_user_id with key values
uids <- uids %>% rename(ref_user_id = old)
d$tweets <- d$tweets %>%
  left_join(uids, by = "ref_user_id", na_matches = "never") %>%
  mutate(ref_user_id = new) %>%
  select(-new)
uids <- uids %>% rename(old = ref_user_id)


# Overwrite $in_reply_to_user_id with key values
uids <- uids %>% rename(in_reply_to_user_id = old)
d$tweets <- d$tweets %>%
  left_join(uids, by = "in_reply_to_user_id", na_matches = "never") %>%
  mutate(in_reply_to_user_id = new) %>%
  select(-new)
uids <- uids %>% rename(old = in_reply_to_user_id)


# Overwrite $ref_in_reply_to_user_id with key values
uids <- uids %>% rename(ref_in_reply_to_user_id = old)
d$tweets <- d$tweets %>%
  left_join(uids, by = "ref_in_reply_to_user_id", na_matches = "never") %>%
  mutate(ref_in_reply_to_user_id = new) %>%
  select(-new)
uids <- uids %>% rename(old = ref_in_reply_to_user_id)

# Step 2: Clean Text, ref_text, and mentions inside then

d$tweets$text_anon <- d$tweets$text %>% tolower()
d$tweets$ref_text_anon <- d$tweets$ref_text%>% tolower()
dat <- d$tweets %>% select(user_id, user_name, text, text_anon, ref_text, ref_text_anon)

# All vars to lower case except "text" and "ref_text" <- will remain the same
# We also need to keep original text varse because CAPS! often are considered by sentiment engines
# -> Sentiment on original text, SNA on mentioning-optimized text
dat <- dat %>% mutate(across(!matches("text$"), tolower))
dat$text_anon <- dat$text_anon %>% str_replace_all("\n", " ") # TODO ARE THERE MORE FIXES TO BE MADE?
dat$ref_text_anon <- dat$ref_text_anon %>% str_replace_all("\n", " ") # TODO ARE THERE MORE FIXES TO BE MADE?


# get all usernames

#py_install("pandas")
#py_install("re")
#py_install("string")

py_run_string("
import re
import string
import pandas as pd
df = r.dat
not_allowed_punct = string.punctuation.replace('_','')
")

py_run_string("

# Get all usernames from user_name variable and text

user_dict = {}

for uid, name in zip(df.user_id, df.user_name):
  if name not in user_dict.keys():
    user_dict[name] = uid
  else:
    continue

# Search mentions in full text_anon, add username if not in dict with 'anon{$count}'

new_user_count = 1
for text in df.text_anon:
  splitted = text.split(' ')
  for word in splitted:
    if len(word)==0:
      continue
    if (word[0] == '@'):
      word_good = ''.join([w for w in word[1:] if w not in not_allowed_punct])
      if word_good not in user_dict.keys():
        user_dict[word_good] = ''.join(['anon', str(new_user_count)])
        new_user_count += 1

# Do the same for ref_text_anon, keep anon count and dict
for text in df.ref_text_anon:
  splitted = text.split(' ')
  for word in splitted:
    if len(word)==0:
      continue
    if (word[0] == '@'):
      word_good = ''.join([w for w in word[1:] if w not in not_allowed_punct])
      if word_good not in user_dict.keys():
        user_dict[word_good] = ''.join(['anon', str(new_user_count)])
        new_user_count += 1

")


py_run_string("

# Substitute mentions in text_anon

all_texts=[]
for text in df.text_anon:
  res = []
  splitted = text.split(' ')
  for word in splitted:
    if len(word)==0:
      continue
    if not (word[0] == '@'):
      res.append(word)
      continue
    else:
      word_good = ''.join(['@']+[w for w in word[1:] if w not in not_allowed_punct])
      if word_good[1:] in user_dict.keys():
        word_good = ''.join(['@',user_dict[word_good[1:]]])
        res.append(word_good)
      else:
        res.append(word)

  all_texts.append(' '.join(res))

df['text_anon'] = all_texts
")

py_run_string("

# Substitute mentions in ref_text_anon

all_texts=[]
for text in df.ref_text_anon:
  res = []
  splitted = text.split(' ')
  for word in splitted:
    if len(word)==0:
      continue
    if not (word[0] == '@'):
      res.append(word)
      continue
    else:
      word_good = ''.join(['@']+[w for w in word[1:] if w not in not_allowed_punct])
      if word_good[1:] in user_dict.keys():
        word_good = ''.join(['@',user_dict[word_good[1:]]])
        res.append(word_good)
      else:
        res.append(word)

  all_texts.append(' '.join(res))

df['ref_text_anon'] = all_texts

")

dat <- py$df
#View(dat)

# Additional anonymous text cleaning (for both text and text_anon)

# @original to @user for unchanged text string
dat$text <- dat$text %>% str_replace_all("@[_[[:alnum:]]]+", "@user")
dat$ref_text <- dat$ref_text %>% str_replace_all("@[_[[:alnum:]]]+", "@user")

# also clean all links from both vars for anonymity because you can just enter them into your browsers
# TO BE DISCUSSED: ONLY t.co links?? for me this is okay, but depends
#dat$text <- dat$text %>% str_replace_all("http.+?(?= )", "")  # https and everything until first instance of whitespace, but does not match if link is at end of string
# This regex is much better and more robust, but only cleans t.co, is okay? bit.ly and stuff always leads to external content, t.co to twtiter content, i.e., sensitive info but need to check this
# Problem is that we never know how long the url is
# Alternative: additional regex with: "if no whitespace found after http, then remove all after http" but have not found out how
dat$text <- dat$text %>% str_replace_all("http[s]{0,1}://t.co/[[:alnum:]]{1,}", "")
dat$ref_text <- dat$ref_text %>% str_replace_all("http[s]{0,1}://t.co/[[:alnum:]]{1,}", "")

# to the same for text_anon and ref_text_anon where necessary
dat$text_anon <- dat$text_anon %>% str_replace_all("http[s]{0,1}://t.co/[[:alnum:]]{1,}", "")
dat$ref_text_anon <- dat$ref_text_anon %>% str_replace_all("http[s]{0,1}://t.co/[[:alnum:]]{1,}", "")

#View(dat)

# TODO THINK OF OTHER WAYS THERE MIGHT BE SENSITIVE INFO IN TEXT; CHECK @USER AND URL REGEXES

# TODO join dat variables back to d$tweets, probably just a $var assignment ....

# Step 3: Check for and omit any other privacy compromising variables

# TODO @all: take a look through all vars and check if any on them could be sensitive
# IDEAS: links in descriptions, affilitated list IDs in data?, media, ...
