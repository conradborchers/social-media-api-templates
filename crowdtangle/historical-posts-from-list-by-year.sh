#! /usr/bin/env bash

# First Argument: Year to download
# Second argument: List ID

# Example usage: `bash historical-posts-from-list-by-year.sh 2015 1461358`

token=$(cat token.txt)

get_year ()
{
printf "\n*** Downloading all post data in $1 for list $2 ***\n\n"
printf "*** Cleaning json/ directory ***\n"
cd json
sleep 2
find . -size 0 -delete
touch .gitkeep
cd ..
printf "\n*** Checking for previous file from year $1 in json/ for obtaining timeframe ***\n\n"
sleep 2
lastfile=$(ls -v json | grep "^$2-$1-" | tail -n 1)
if ! [[ -z $lastfile ]]
then
      printf "*** Found file: $lastfile ***\n"
	  list_char_len=${#2}
	  let list_char_len+=6
	  count=$(echo ${lastfile:list_char_len} | sed 's/.json//g')
	  let count+=1
	  printf "*** Will count files starting at $count ***\n"
	  end=$(tail -c 10000 json/$lastfile | grep -oP '\"date\":\"[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}' | tail -n 1 | sed 's/[a-z\"]*//g' | cut -c2- | sed 's/ /T/g')
	  printf "*** Start date form last session found at $end ***\n"
	  sleep 2
else
      printf "*** Found NO previous file for list $2 in year $1, will set default start value ***\n\n"
	  end="$1-12-31T23:59:59"
	  let count=1
	  printf "*** Start date set to $end ***\n"
	  sleep 2
fi
start="$1-01-01T00:00:00"
printf "*** Initializing download... ***\n\n"
printf "*** Files will be stored in directory json/ with signature $2-$1-{1,2,...n} ***\n\n"
sleep 1
let returned=999
while [[ returned -gt 149 ]]
do
  touch json/$2-$1-$count.json
  printf "*** Trying to download $start until $end into json/$2-$1-$count.json... ***\n\n"
  while [[ $(head -c 50 json/$2-$1-$count.json | grep -oP '^[^0-9]*\K[0-9]+') -ne 200 ]]
  do
    curl --max-time 90 "https://api.crowdtangle.com/posts?token=$token&startDate=$start&endDate=$end&listIds=$2&sortBy=date&count=10000" > json/$2-$1-$count.json
	if [[ $(head -c 50 json/$2-$1-$count.json | grep -oP '^[^0-9]*\K[0-9]+') -ne 200 ]]
	then 
	  printf "\n*** Last download returned bad status or failed. Setting console to sleep for 10 seconds and retrying ***\n\n"
	  sleep 10
	fi
  done
  end=$(tail -c 10000 json/$2-$1-$count.json | grep -oP '\"date\":\"[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}' | tail -n 1 | sed 's/[a-z\"]*//g' | cut -c2- | sed 's/ /T/g')
  returned=$(head -c 150 json/$2-$1-$count.json | wc -c) # empty responses (no more data to be downloaded at last query) have < 150 bytes
  let count+=1
done	
let count-=1
rm json/$2-$1-$count.json # remove last return as it is empty
printf "*** YEAR $1 DOWNLOAD FOR LIST $2 COMPLETE ***\n\n"
} 

get_year $1 $2
