#! /bin/bash

#
# Efficiently find duplicated files in multiple directory hierarchies.
# Copyright 2007-2008 S. Fuhrmann <s_fuhrm@web.de>
# $Id: dupfind.sh 9 2008-01-19 22:32:56Z fury $

# sort -r : reverse order

#trap 'pkill -P $$' 2
trap : 2 3 15


STRATEGY="RM"
AWKSCRIPT=/tmp/awk.$$

cat > $AWKSCRIPT <<FOOBAR
BEGIN { 
	FS = "\t"; 
	count=0; 
	dupes=0; 
	oldpath=""; 
	oldname=""; 
	oldsize=""; 
	totalsize=0; 
	totaldupsize=0;
} 
{ 
	path=\$1; 
	name=\$2; 
	size=\$3; 
	count++; 
	totalsize+=size; 
	if ( size == oldsize && size>0 && path != oldpath ) {
		val=system("cmp -s \""path"\" \""oldpath"\""); 
		if (val==0) { 
			print "# Because of \""oldpath"\""; 
			if (name!=oldname) {
				print "# Note the different name!" 
			} 
			print "rm \""path"\""
		}; 
		dupes++; 
		totaldupsize+=size; 
	}
	oldpath=path; 
	oldname=name; oldsize=size
}; 
END { 
	print "# Total files: "count", total size: "totalsize"="totalsize/(1024*1024)"MB, duplicates: "dupes", duplicates size: "totaldupsize"="totaldupsize/(1024*1024)"MB"
}
FOOBAR

(
	find -H "$@" -type f -printf "%s\t%f\t%p\n" |
	sort -r |
	awk -- '{FS = "\t"; print $3"\t"$2"\t"$1 }'|
	uniq -d -D -f 1|
	awk -f $AWKSCRIPT
) &
CHILD_PID=$!

wait $CHILD_PID

if [[ $? -gt 128 ]]
then
    pkill -P $CHILD_PID
fi
