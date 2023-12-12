#/usr/bin/env bash

config="$(cat "$XDG_CONFIG_HOME/xioxide/dirs.conf")"
indent=""

while IFS= read -r line; do
    [ -z "$indent" ] && [ -z "$(echo "$line" )" ]
    echo "$line"
done <<< "$config"
