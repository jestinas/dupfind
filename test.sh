# /bin/bash

STDOUT=/tmp/stdout.$$
STDERR=/tmp/stderr.$$

for i in test/*; do
	if [ -d $i ]; then
		echo $i
		./dupfind.sh $i > $STDOUT 2> $STDERR
		
		for FILE in stdout stderr; do
			TMPFILE=/tmp/$FILE.$$
			if ! cmp $TMPFILE $i.$FILE; then
				echo "$FILE differs for $i:"
				diff $TMPFILE $i.$FILE
				echo "See also in $TMPFILE"
				exit
			fi
		done
		echo $i ... OK
	fi
done
