#!/usr/bin/env bash

case "$1" in
    "help") cat "$XIOXIDE_PATH/README.md" ;;
    "config")
	cat "$XDG_CONFIG_HOME/xioxide/$2.conf"
	echo "---"
	cat "$XDG_CONFIG_HOME/xioxide/$2.parsed"
	;;
    "reload")
	if [ -z "$2" ]; then
	    for file in $XDG_CONFIG_HOME/xioxide/*.conf; do
	        "$XIOXIDE_PATH/reload.sh" "$file"
	    done
	else
	    "$XIOXIDE_PATH/reload.sh" "$XDG_CONFIG_HOME/xioxide/$2.conf"
	fi
	;;

    *)
	XIOXIDE_OUTPUT="$("$XIOXIDE_PATH/xioxide.sh" "$2" "$3" "$4" "$5")"
	[ -z "$1" ] && XIOXIDE_RUNNER="echo" || XIOXIDE_RUNNER="$1"

	if [ -n "$XIOXIDE_OUTPUT" ]; then
	    $XIOXIDE_RUNNER "$XIOXIDE_OUTPUT"
	else
	    if [ "$6" != "--no-passthrough" ]; then
		[ -z "$5" ] && $XIOXIDE_RUNNER || $XIOXIDE_RUNNER "$5"
            fi
	fi
	;;
esac
