## Documentation on Downloading and Cleaning Conversations

### Goal

Obtain all tweets that 
replied to tweets in the main data set
as well as any tweets that replied to those
replies recursively (_forward reply chain_).

### Sampling

For all unique tweets in the data set,
filter those that received at least one reply and
extract unique instances of
the variable `conversation_id` from
the set of those tweets. 
Implementation: `extract-conversations.r`

### Downloading and API responses

Download all obtained Conversation IDs
through the following endpoint:
`https://api.twitter.com/2/tweets/search/all?query=conversation_id:$q&max_results=$max&until_id=$until$vars`
Implementation: `main-conversations.sh`, `functions.sh`, 
and for downloading multiple conversations automatically,
`search-conversations.sh`. 

This search returns all tweets connected
to the sampled conversation IDs. If the 
tweet corresponding to a sampled conversation
ID is a conversation starter (i.e., is not
a reply itself), then the conversation ID
is equivalent to the status ID of that tweet.

Notice that tweets from the main data set 
from which the conversation IDs were sampled
must not necessarily be conversation starters
and might be replies themselves. This means that
some tweets in the API responses are tweets
that were posted before the corresponding
tweet in the main data set (and were replied to by
tweets in the main data set). Usually, we want
to only include tweets _in response to tweets in the main data set_
(and not the tweets that the tweets in the main
data set have replied to), so we have to select
the tweets in the API responses manually and accordingly.

This selection criterion is further referred to as
_forward-search_.

### Choosing the correct tweets from the API responses

In order to perform a forward-search in the API responses, 
we perform the following
steps, which
is implemented in `inspect-conversations.r`:

1. For each conversation ID downloaded, obtain the oldest
tweet in the main data set and store its creation time
in a hash table with the conversation ID as key.

2. For each tweet in the API responses from the conversation
ID search endpoint, check if the variable `ref_conversation_id`
(in which the conversation ID which was contributed to is 
represented) is a key in the hash table from `1.`.
Then, only include the tweet in the final sample of forward replies
if the creation date of the tweet is more recent than
the oldest tweet of the corresponding conversation ID
in the main data set, corresponding to the value (time) to
the key (conversation ID) in the hash table.

3. Remove tweets already present in the main data set 
and mark the additional tweets obtained through the
forward search through a binary variable 
(currently named `is_forward_reply`).

To perform these steps, we sample the variables status_id, 
created_at, and conversation_id from the tweets the conversation
IDs of which we have sampled previously. They are stored temporarily
in `reply-reference.rds` as created in `extract-conversations.r`.

### Merging back

The results of this forward search are then merged back to the
main data set, such that the full data set can then be
anonymized.
