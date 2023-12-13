#!/usr/bin/env bash

[ -n "$1" ] && filter_cmd="$1" || filter_cmd="cat"
[ -n "$2" ] && current_cmd="$2" || current_cmd="echo"
[ -n "$3" ] && config_stem="$3" || config_stem="default"
search_pattern="$4"

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

absolute_pattern() {
    echo "$item_list" | greps "^$search_pattern " | head -n 1 | awk '{ print $2 }'
}

relative_pattern() {
    search_pattern="$(current_name)$(echo "$search_pattern" | sed 's/^.//')"
    absolute_pattern
}

absolute_interactive() {
    echo "$item_list" | fzf | awk '{ print $2 }'
}

relative_interactive() {
    echo "$item_list" | greps "^$(current_name)" | sed "s|$(current)|.|" | fzf | awk '{ print $2 }'
}

if [ -z "$search_pattern" ]; then
    absolute_interactive
elif [ "$search_pattern" == "." ]; then
    relative_interactive
elif [ -n "$(echo "$search_pattern" | grep '^\.')" ]; then
    relative_pattern
else
    absolute_pattern
fi
