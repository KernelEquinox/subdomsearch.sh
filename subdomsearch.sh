#!/bin/bash

##################################################################
#                                                                #
#              Subdomain Enumeration Script by Cry0              #
#                                                                #
# This script essentially enumerates every subdomain in a domain #
#   (or at least attempts to). If it can't, then it enumerates   #
#                  all the domains that it can.                  #
#                                                                #
##################################################################



query_array=() # Initialize the array to hold our full query.
curr_array_count=0 # Initialize the count of the current array length.
prev_array_count=0 # Initialize the count of the previous array length.

# This function basically interfaces with the google() function and formats it nicely.
# It also helps with printing out our current progress.
function get_urls {
	prev_array_count=${#query_array[*]};
	# Enumerate returned unique subdomains and strip everything but each subdomain's name.
	for i in $(google "$1" | sed 's/http[s]*\:\/\/\([A-Za-z0-9\-]*\).*/\1/g' | sort -u); do
		# Add -site:[subdomain].* to the query in order to filter out what we already know.
		query_array+=('-site:'$i'.*');
	done
	curr_array_count=${#query_array[*]};
}

# Inserts the specified query into a Google search query and formats it as if it were a legitimate browser request.
function google {
	Q="$1";
	GOOG_URL="http://www.google.com/search?q=";
	AGENT="Mozilla/4.0";
	stream=$(curl -A "$AGENT" -skLm 10 "${GOOG_URL}\"${Q/\ /+}\"" | grep -oP '\/url\?q=.+?&amp' | sed 's/\/url?q=//;s/&amp//');
	echo -e "${stream//\%/\x}"
}

# Check to make sure we haven't hit our 32-query limit.
# If we have, terminate the script and sudoku.
function check_query {
	full_list=$(echo ${query_array[*]} | tr ' ' '\n' | sort | wc -l); # The full list including repeated queries.
	unique_list=$(echo ${query_array[*]} | tr ' ' '\n' | sort -u | uniq | wc -l); # The list with only unique queries.
	# Check to see if this query is the same as the last one, indicating we reached the query cap.
	if [ $full_list -ne $unique_list ]; then
		echo -e "[\033[1;1;31m!\033[0m] We hit our search query limit!";
                quit_script $1;
	fi
}

# Buh-bye.
function quit_script {
        echo -e "[\033[1;1;34m-\033[0m] Saving subdomain list to \033[1;32m"$1".subdomains\033[0m";
        echo ${query_array[*]} | tr " " "\n" | sed 's/-site\:\([A-Za-z0-9\-]*\).*/\1/g' | grep -v "^site\:.*$" | sort -u > $1".subdomains";
	exit;
}

query_array=('site:'$1) # Set our initial query to the specified domain.

if [ "$#" -ne 1 ]; then
	echo "Usage: subdomsearch.sh [domain.tld]";
	exit;
fi

# Loop through the results until we get what we came for.
while true; do
	echo -e -n "[\033[1;1;34m*\033[0m] Executing our query..."
	get_urls "$(echo ${query_array[*]})";
	echo -n "done! ";
	# This checks if there weren't any results returned.
	if [ $prev_array_count -eq $curr_array_count ]; then
		echo;
		echo;
		echo -e "[\033[1;1;32m!\033[0m] Looks like that's all of the subdomains."
		quit_script $1;
	fi
	echo -e "Found \033[1;32m"$(($curr_array_count - $prev_array_count))"\033[0m new subdomains."
	echo -e "[\033[1;1;33m.\033[0m] Waiting 10 seconds between queries to avoid lockout...";
	echo;
	sleep 10;
	check_query $1;
done
quit_script $1 # Fallback in case [ 1 -ne 1 ]
