#!/usr/bin/env bash

case "$1" in
    "help") cat "$XIOXIDE_PATH/help.txt" ;;

    "reload") "$XIOXIDE_PATH/reload-config.sh" ;;

    "cd") cd "$("$XIOXIDE_PATH/xioxide.sh" "grep '/$'" "$2")" ;;

    "edit") cd "$("$XIOXIDE_PATH/xioxide.sh" "grep -v '/$'" "$2")" ;;

    *) "$1" "$("$XIOXIDE_PATH/xioxide.sh" "$2" "$3" "$4" "$5")" ;;
	# the first arg is the program to run on the outcome
	# the second arg is the filter to run the list of items through
	# the third arg is the search pattern
	# the fourth arg is a command to get the current open item (directory)
esac
