#! /usr/bin/env bash

# Windows encoding fix
sed -i 's/\r$//g' queries.txt

touch downloaded.txt
while [[ $(wc -l < queries.txt) -gt 0 ]]
do
	q=$(head -n 1 queries.txt)
	bash main.sh $q
	echo $q >> downloaded.txt
	sed -i 1d queries.txt	
	sleep 3
done
printf "\n\n*** All queries in queries.txt downloaded ***\n\n"
