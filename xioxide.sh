#!/usr/bin/env bash

# argument defaults and setup ...
[ -n "$1" ] && filter_cmd="$1" || filter_cmd="cat"
[ -n "$2" ] && current_cmd="$2" || current_cmd="echo"
[ -n "$3" ] && default_cmd="$3" || default_cmd="echo"
[ -n "$4" ] && config_stem="$4" || config_stem="default"
search_pattern="$5"
[ -z "$search_pattern" ] && exit

eval "filter() { cat | "$filter_cmd"; }"
eval "fn_current() { "$current_cmd"; }"
eval "default_item() { "$default_cmd"; }"
config_path="$XDG_CONFIG_HOME/xioxide/$config_stem.parsed"
sed_path="$XDG_CONFIG_HOME/xioxide/$config_stem.sed"

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
    predots="$(echo "$search_pattern" | sed 's|[^.].*$||')"   # "..." -> "..." (deletes to eol once it hits a non-'.' character)
    letters="$(echo "$search_pattern" | sed 's|\.||g')"       # "..." -> "" (removes all dots)
    postdot="$(echo "$search_pattern" | sed 's|^\.*[^.]*||')" # "..." -> "" (if there are dots at start, deletes them, and then delets any non-'.' letters after that)
fi

# handle predots
current_item="$(fn_current | sed -e 's|\.|\\\.|g' -e 's|\^|\\\^|g' -e 's|\$|\\\$|g')" # this just takes the current item and applies escape sequences (for matching with grep)
current_name="$(echo "$item_list" | grep " $current_item$" | head -n 1 | awk '{ print $1 }')"
[ -z "$current_name" ] && current_name="$(echo "$item_list" | grep " $current_item" | head -n 1 | awk '{ print $1 }')"
[ -z "$current_name" ] && exit
# the above just tries its best to find a xioxide item that best matches the current_item

if [ "$predots" == "." ] || default_item "$current_item"; then
    [ -f "$sed_path" ] && letters="$(echo "$letters" | sed -f "$sed_path")"
elif [ -z "$predots" ]; then
    item_list="$(echo "$item_list" | grep "^$current_name" | sed "s|^$current_name||")" # basically just makes the item_list relative to current_name
else
    for ((i = 1; i < ${#predots}; i++)); do
        echo "$current_name" | grep -q '_' || exit # if we run out of underscores, this means the amount of dots user entered implies going above the tree
        current_name="$(echo "$current_name" | sed 's|_[^_]*$||')" # essentially deletes the lowest level specifier (from 'a_b_c' remove '_c')
    done

    item_list="$(echo "$item_list" | grep "^$current_name" | sed "s|^$current_name||")" # basically just makes the item_list relative to current_name
fi

[ -z "$item_list" ] && exit # in case no matches (shouldn't really happen)

# :a means add a mark (like a goto)
# \( ... \) is a capture group
# \1 means whatever the (first) capture group captured
# ta means go back to 'a' if the previous substitution did something
item_list="$(echo "$item_list" | sed ':a;s|^\([a-z]*\)_|\1|;ta')"
# remove the underscores from the names of all of the items

# handle letters
[ -n "$letters" ] && final_item_list="$(
    echo "$item_list" | grep "^$letters " | sed "s|^$letters||"
    echo "$item_list" | grep "^$letters"'[^ ]' | sed "s|^$letters||"
)"
[ -z "$final_item_list" ] && exit

# handle postdot(s?)
if [ -n "$postdot" ]; then
    echo "$final_item_list" | fzf | sed 's|^[^ ]* ||'
else
    echo "$final_item_list" | head -n 1 | sed 's|^[^ ]* ||'
fi
