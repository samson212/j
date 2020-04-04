#!/usr/bin/awk -f
BEGIN {
	date=0;
	sum=0;
	count=0;
	print "DATE", "RATING", "ENTRIES";
}

# entry headers with ratings
/^  \[.*\] rating:/ {
	count++;
	sum += $4;
}

# date lines
/^=== / {

	if (date > 0) {
		# we only need to print if this isn't the first date
		print date, ((count > 0) ? (sum / count) : "--"), count;
	}

	# save the new date and reset the counters
	date=$2;
	sum=0;
	count=0;

}

# handle the final date
END {
	if (date > 0 && count > 0) {
		print date, (sum / count), count;
	}
}
