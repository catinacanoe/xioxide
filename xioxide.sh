#!/usr/bin/env bash

# argument defaults and setup ...
[ -n "$1" ] && filter_cmd="$1" || filter_cmd="cat"
[ -n "$2" ] && current_cmd="$2" || current_cmd="echo"
[ -n "$3" ] && config_stem="$3" || config_stem="default"
search_pattern="$4"
[ -z "$search_pattern" ] && exit

eval "filter() { cat | "$filter_cmd"; }"
eval "fn_current() { "$current_cmd"; }"
config_path="$XDG_CONFIG_HOME/xioxide/$config_stem.parsed"

[ -f "$config_path" ] || exit 1

item_list="$(cat "$config_path" | filter)"

# separate out search pattern (and handle ".")
if [ "$search_pattern" == "." ]; then
    predots=""
    letters=""
    postdot="."
elif [ "$search_pattern" == ".." ]; then
    predots="."
    letters=""
    postdot="."
else
    predots="$(echo "$search_pattern" | sed 's|[^.].*$||')" # "..." -> "..."
    letters="$(echo "$search_pattern" | sed 's|\.||g')" # "..." -> ""
    postdot="$(echo "$search_pattern" | sed 's|^\.*[^.]*||')" # "..." -> ""
fi

# handle predots
if [ -n "$predots" ]; then
    current_item="$(fn_current | sed -e 's|\.|\\\.|g' -e 's|\^|\\\^|g' -e 's|\$|\\\$|g')"
    current_name="$(echo "$item_list" | grep " $current_item$" | head -n 1 | awk '{ print $1 }')"
    [ -z "$current_name" ] && current_name="$(echo "$item_list" | grep " $current_item" | head -n 1 | awk '{ print $1 }')"
    [ -z "$current_name" ] && exit

    for (( i=1; i<${#predots}; i++ )); do
	[ -z "$(echo "$current_name" | grep '_')" ] && exit # we are trying to go above the xioxide tree
	current_name="$(echo "$current_name" | sed 's|_[^_]*$||')" # a '_' and then any non '_' chars at the $end
    done

    item_list="$(echo "$item_list" | grep "^$current_name" | sed "s|^$current_name||")"
    [ -z "$item_list" ] && exit # no matches (shouldn't really happen)
fi

# :a means add a mark (like a goto)
# \( ... \) is a capture group
# \1 means whatever the (first) capture group captured
# ta means go back to 'a' if the previous substitution did something
item_list="$(echo "$item_list" | sed ':a;s|^\([a-z]*\)_|\1|;ta')"
# remove the underscores from the names of all of the items

# handle letters
[ -n "$letters" ] && item_list="$(echo "$item_list" | grep "^$letters" | sed "s|^$letters||")"
[ -z "$item_list" ] && exit

# handle postdot(s?)
if [ -n "$postdot" ]; then
     echo "$item_list" | fzf | sed 's|^[^ ]* ||'
else
     echo "$item_list" | head -n 1 | sed 's|^[^ ]* ||'
fi
