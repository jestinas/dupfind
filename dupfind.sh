#! /bin/bash

#
# Efficiently find duplicated files in multiple directory hierarchies.
# Copyright 2007-2016 S. Fuhrmann <s_fuhrm@web.de>

DEBUG=0
REMOVALSTRATEGY="RM"
SELECTIONSTRATEGY="SHORTESTPATH"
while getopts "hds:r:" opt; do
  case $opt in
    h)
      echo "dupfind.sh (C) 2007-2016 S.Fuhrmann <s_fuhrm@web.de>" >&2
      echo "" >&2
      echo "-h...This command line help" >&2
      echo "-d...Debug the script (only for development)" >&2
      echo "-r...Removal strategy: One of RM (default), LNS, LN or NOP" >&2
      echo "-s...Selection strategy: One of FIRST, SHORTESTPATH, LONGESTPATH" >&2
      exit
      ;;
    d)
	DEBUG=1
	;;
    r)
	REMOVALSTRATEGY=${OPTARG}
	case $REMOVALSTRATEGY in
		RM | LNS | LN | NOP)
			;;
		*)
			echo "Unknown removal strategy ${OPTARG}"
			exit
			;;
	esac
	;;
    s)
	SELECTIONSTRATEGY=${OPTARG}
	case $SELECTIONSTRATEGY in
		FIRST | SHORTESTPATH | LONGESTPATH)
			;;
		*)
			echo "Unknown selection strategy ${OPTARG}"
			exit
			;;
	esac
	;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
  esac
done
shift $((OPTIND-1))

trap : 2 3 15

TMPGROUP=/tmp/group.$$
AWKCOMPARE=/tmp/awk.compare.$$
AWKSELECT=/tmp/awk.select.$$
AWKREMOVE=/tmp/awk.remove.$$
AWKSTATS=/tmp/awk.stats.$$
AWKSAFE=/tmp/awk.safe.$$

#
# This is the basic duplicate grouping script
#
cat > $AWKCOMPARE <<FOOBAR
function checksum(path) {
	"sha1sum -b \""path"\"" |& getline val
	count=split(val, a, " ")
	return a[1]
}
function addsum(sum,path,group) {
	group[sum][path]=1
}
function flushgroup(group) {
	for (sum in group) {
		first = 1
		len=0
		# count array elements 
		for (file in group[sum]) {
			len++
		}
		# only elements with 2 entries
		if (len < 2) {
			continue
		}
		for (file in group[sum]) {
			sep = first==1 ? "" : "\t";
			printf("%s\"%s\"",sep,file);
			first = 0
		}
		printf("\n");
	}
}
BEGIN { 
	FS = "\t"; 
	oldpath=""; 
	oldname=""; 
	oldsize=""; 
	ingroup=0;
	group_pos=0
	delete group
}
{
	path=\$1; 
	name=\$2; 
	size=\$3; 
	count++; 
	totalsize+=size; 
	if ( size == oldsize && size>0 ) {
		if (!ingroup) {
			oldsum=checksum(oldpath)
			addsum(oldsum,oldpath,group)
		}
		sum=checksum(path)
		addsum(sum,path,group)
		ingroup=1
	} else {
		ingroup=0
		flushgroup(group)
		delete group
	}
	oldpath=path; 
	oldname=name; oldsize=size
}; 
END { 
	flushgroup(group)
	delete group
}
FOOBAR

if [ "$SELECTIONSTRATEGY" = "FIRST" ]; then
#
# FIRST selection script 
#
cat > $AWKSELECT <<FOOBAZ
BEGIN { 
	FS = "\t"; 
} 
{
	if (NF >= 2) {
		print
	}
}; 
END { 
}
FOOBAZ
fi

if [ "$SELECTIONSTRATEGY" = "SHORTESTPATH" ]; then
#
# SHORTESTPATH selection script 
#
cat > $AWKSELECT <<FOOBAZ
BEGIN { 
	FS = "\t"; 
} 
{
	MIN=-1
	MINELEMENT=0
	for(i = 1; i <= NF; i++) {
		if (MIN == -1 || length(\$i) < MIN) {
			MIN=length(\$i)
			MINELEMENT=\$i
		}
	}
	if (NF >= 2) {
		printf("%s", MINELEMENT);
		for(i = 1; i <= NF; i++) {
			if (\$i != MINELEMENT) {
				printf("\t%s", \$i);
			}
		}
		printf("\n");
	}
}; 
FOOBAZ
fi

if [ "$SELECTIONSTRATEGY" = "LONGESTPATH" ]; then
#
# LONGESTPATH selection script 
#
cat > $AWKSELECT <<FOOBAZ
BEGIN { 
	FS = "\t"; 
} 
{
	MAX=-1
	MAXELEMENT=0
	for(i = 1; i <= NF; i++) {
		if (MAX == -1 || length(\$i) > MAX) {
			MAX=length(\$i)
			MAXELEMENT=\$i
		}
	}
	if (NF >= 2) {
		printf("%s", MAXELEMENT);
		for(i = 1; i <= NF; i++) {
			if (\$i != MAXELEMENT) {
				printf("\t%s", \$i);
			}
		}
		printf("\n");
	}
}; 
FOOBAZ
fi


if [ "$REMOVALSTRATEGY" = "RM" ]; then
#
# RM removal script 
#
cat > $AWKREMOVE <<FOOBAZ
BEGIN { 
	FS = "\t"; 
} 
{
	MAX=-1
	MAXELEMENT=0
	printf ("# Keeping %s\n", \$1)
	for(i = 2; i <= NF; i++) {
		printf ("rm %s\n", \$i)
	}
}; 
FOOBAZ
fi

if [ "$REMOVALSTRATEGY" = "LNS" ]; then
#
# LNS removal script 
#
cat > $AWKREMOVE <<FOOBAZ
BEGIN { 
	FS = "\t"; 
} 
{
	MAX=-1
	MAXELEMENT=0
	printf ("# Keeping %s\n", \$1)
	for(i = 2; i <= NF; i++) {
		printf ("ln -sf %s %s\n", \$1, \$i)
	}
}; 
FOOBAZ
fi

if [ "$REMOVALSTRATEGY" = "LN" ]; then
#
# LN removal script 
#
cat > $AWKREMOVE <<FOOBAZ
BEGIN { 
	FS = "\t"; 
} 
{
	MAX=-1
	MAXELEMENT=0
	printf ("# Keeping %s\n", \$1)
	for(i = 2; i <= NF; i++) {
		printf ("ln -f %s %s\n", \$1, \$i)
	}
}; 
END { 
}
FOOBAZ
fi

if [ "$REMOVALSTRATEGY" = "NOP" ]; then
#
# NOP removal script 
#
cat > $AWKREMOVE <<FOOBAZ
{
};
FOOBAZ
fi

#
# Safe compare script
#
cat > $AWKSAFE <<FOOBAZ
BEGIN { 
	FS = "\t"; 
} 
{
	MATCH=1
	for(i = 2; i <= NF; i++) {
		val=system("cmp -s "\$1" "\$i);
		if (val!=0) {
			print("# Sorting out again, SHA1 match but CMP mismatch: "\$1" "\$i) > "/dev/stderr"
			MATCH=0
		}
	}
	if (MATCH) {
		print
	}
}; 
END {
}
FOOBAZ

#
# Statistics script
#
cat > $AWKSTATS <<FOOBAZ
BEGIN { 
	FS = "\t"; 
	DUPSIZE=0
	DUPCOUNT=0
} 
{
	"stat --printf=\"%s\" "\$1 |& getline SIZE
	for(i = 2; i <= NF; i++) {
		DUPCOUNT++;
		DUPSIZE+=SIZE;
	}
	print
}; 
END {
	UNIT="B"
	DIV=1
	if (DUPSIZE > 1024*1024) {
		UNIT="MB"
		DIV=1024*1024
	} else if (DUPSIZE > 1024) {
		UNIT="KB"
		DIV=1024
	}
	print("# Stats: duplicates="DUPCOUNT", dupsize="DUPSIZE/DIV""UNIT) > "/dev/stderr"
}
FOOBAZ

# this is the main subprocess
(
	# format for pipe infos is: 
	find -H "$@" -type f -printf "%s\t%f\t%p\n" |
	# Line format: bytesize\tfilename\tfullpath
	# Sort in reverse order
	sort -r -n |
	# Sort in reverse order
	awk -- '{FS = "\t"; print $3"\t"$2"\t"$1 }'|
	# Line format: fullpath\tfilename\tbytesize
	gawk -- 'BEGIN{FS="\t"; old=""}; {if (oldkey == $3) {if (old) {print old} print $0; old=0} else {old=$0}; oldkey=$3 };' |
	gawk -f $AWKCOMPARE |
	# Line format: dup1\tdup2\tdup3...
	awk -f $AWKSELECT | 
	awk -f $AWKSAFE | 
	awk -f $AWKSTATS | 
	awk -f $AWKREMOVE 
) &
CHILD_PID=$!

wait $CHILD_PID

if [[ $? -gt 128 ]]
then
    pkill -P $CHILD_PID
fi

if [ "$DEBUG" == "0" ]; then
	rm -f $AWKCOMPARE
	rm -f $AWKSELECT
	rm -f $AWKREMOVE
	rm -f $AWKSTATS
fi
