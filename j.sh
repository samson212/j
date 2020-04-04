#!/bin/sh

set -x

# default editor to vi
if [ -z "$EDITOR" ]; then
	editor=vi
else
# otherwise use the system editor
	editor=$EDITOR
fi

# file references
journal=$HOME/journal
tmpfile=/tmp/j.$$

# file handling
trap "rm -f $tmpfile" EXIT
touch $tmpfile

# date variables
today=$(date -I)
now=$(date +"%Hh%M %z")
lastdate=$(grep '^===' $journal | tail -n 1 | sed 's/ *=== *//g')

# handle command line arguments
args=$(getopt r:f:t: $*)
if [ $? -ne 0 ]; then
	echo 'usage: j [-r rating] [-f from] [-t to] [msg...]'
	exit 2
fi
set -- $args

# get variables for arguments
rating=""
while [ $# -ne 0 ]
do
	case "$1" in
		-r) rating="$2"; shift;;
		-f) from="$2"; shift;;
		-t) to="$2"; echo "to '$2'"; shift;;
		--) shift; break;;
	esac
	shift
done

# if we're viewing, just retrieve
if [ ! -z $from ]; then
	fromDate=$(date --date="$from" -I)
	if [ ! -z $to ]; then
		toDate=$(date --date="$to" -I)
		awk 'BEGIN { foundFrom=0; fromDate="'"$fromDate"'"; toDate="'"$toDate"'"; }
			{
				if ($1 == "===") {
					if ($2 > toDate)						{ exit; }
					if (foundFrom == 0 && $2 >= fromDate)	{ foundFrom++; }
				}
				if (foundFrom > 0) { print $0; }
			}' <$journal
	else
		awk 'BEGIN { foundFrom=0; fromDate="'"$fromDate"'"; }
			{
				if (foundFrom==0 && $1 == "===" && $2 >= fromDate) { foundFrom++; }
				if (foundFrom>0) { print $0; }
			}' <$journal
	fi
	exit
elif [ ! -z $to ]; then
	toDate=$(date --date="$to" -I)
	awk 'BEGIN { toDate="'"$toDate"'"; } { if ($1 == "===" && $2 > toDate) { exit; } print $0; }' <$journal
	exit
fi

# handle the entry
if [ -z "$*" ]; then
	# no arguments, go to the editor
	echo $*
	$editor $tmpfile
else
	# text was specified as arguments
	echo $* >>$tmpfile
fi

# indent the body of the entry by two spaces
sed -i 's/^/  /g' $tmpfile

# prepend the timestamp and metadata-- if we had done this before, it would be visible in the editor
metadata=""
if [ ! -z $rating ]; then
	metadata=" rating: $rating"
fi
echo "[$now]$metadata\n$(cat $tmpfile)" > $tmpfile

# append the entry to the actual journal file
(
	# prepend the date and a newline if it's the first entry for the day
	if ! [ "$today" = "$lastdate" ]; then
		echo
		echo "=== $today ==="
	fi
	echo "  "

	# now indent another two spaces and output the entry and heading
	sed 's/^/  /g' <$tmpfile
)>>$journal
