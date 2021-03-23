#! /usr/bin/env bash

# Windows encoding fix
sed -i 's/\r$//g' cids-forward.txt

touch downloaded-cids.txt
while [[ $(wc -l < cids-forward.txt) -gt 0 ]]
do
	SECONDS=0
	q_c=$(head -n 1 cids-forward.txt)
	sed -i 1d cids-forward.txt
	q_f=$(head -n 1 cids-forward.txt)
	sed -i 1d cids-forward.txt
	q_m=$(head -n 1 cids-forward.txt)
	sed -i 1d cids-forward.txt
	mintty bash main-conversations.sh $q_c token-christian.txt &
	#mintty bash main-conversations.sh $q_f token-fitore.txt &
	mintty bash main-conversations.sh $q_m token-mario.txt &
	wait
	echo $q_c >> downloaded-cids.txt
	echo $q_f >> downloaded-cids.txt
	echo $q_m >> downloaded-cids.txt
	while ! [[ $SECONDS -ge 3 ]]; do sleep 0.1; done	
	sleep 0.1
done
printf "\n\n*** All conversation IDs in in cids.txt downloaded ***\n\n"
