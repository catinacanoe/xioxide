#!/usr/bin/env bash

[ -n "$1" ] && filter_cmd="$1" || filter_cmd="cat"
[ -n "$2" ] && current_cmd="$2" || current_cmd="echo"
[ -n "$3" ] && config_stem="$3" || config_stem="default"
search_pattern="$4"

[ "$search_pattern" == ".." ] && exit
[ -z "$search_pattern" ] && exit

eval "filter() { cat | "$filter_cmd"; }"
eval "current() { "$current_cmd"; }"
config_path="$XDG_CONFIG_HOME/xioxide/$config_stem.parsed"

if ! [ -f "$config_path" ]; then
    echo "the parsed configuration file '$config_path' does not exist, exiting ..."
    exit 1
fi

item_list="$(cat "$config_path" | filter)"

greps() {
    cat | grep "$(echo "$1" | sed -e 's|\.|\\\.|g')"
}

current_name() {
    ret="$(echo "$item_list" | greps " $(current)" | head -n 1 | awk '{ print $1 }')"
    [ -z "$ret" ] && exit || echo "$ret"
}

match_pattern() {
    echo "$item_list" | greps "^$search_pattern " | head -n 1 | awk '{ print $2 }'
}

pattern_mk_absolute() {
    search_pattern="$(current_name)$(echo "$search_pattern" | sed 's/^.//')"
}

interactive() {
    echo "$item_list" | fzf | awk '{ print $2 }'
}

list_mk_relative() {
    item_list="$(echo "$item_list" | greps "^$1")"
}

list_mk_relative_current() {
    list_mk_relative "$(current_name)"
}

list_mk_relative_pattern() {
    list_mk_relative "$(echo "$search_pattern" | sed 's|\.$||')"
}

if [ -z "$search_pattern" ]; then
    exit
elif [ "$search_pattern" == "*" ]; then
    interactive
elif [ "$search_pattern" == "." ]; then
    list_mk_relative_current
    interactive
elif [ -n "$(echo "$search_pattern" | grep '^\.' | grep '\.$')" ]; then
    pattern_mk_absolute
    list_mk_relative_pattern
    interactive
elif [ -n "$(echo "$search_pattern" | grep '^\.')" ]; then
    pattern_mk_absolute
    match_pattern
elif [ -n "$(echo "$search_pattern" | grep '\.$')" ]; then
    list_mk_relative_pattern
    interactive
else
    match_pattern
fi
