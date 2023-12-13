#/usr/bin/env bash

infile="$1"
outfile="$(echo "$infile" | sed 's|.conf$|.parsed|')"

echo "xioxide reloading config file: '$infile'"

if ! [ -f "$infile" ]; then 
    echo "error while reading config: '$infile' does not exist, exiting"
    exit 1
fi

rm "$outfile"

config="$(cat "$infile" | sed -e '/^\s*$/d' -e '/^\s*#/d')"

get_indent_size() {
    echo "$1" | sed 's/[^[:space:]].*//' | tr -d '\n' | wc -c
}

indent_size=""
name=""
value=""
while IFS= read -r line; do
    current_indent="$(get_indent_size "$line")"

    [ "$(get_indent_size "$line")" != "0" ] && [ -z "$indent_size" ] && \
	indent_size="$current_indent"

    if [ -z "$indent_size" ]; then
	indent_count="0"
    else
        indent_count="$(echo "$current_indent/$indent_size" | bc)"
    fi

    local_name="$(echo "$line" | awk '{ print $1 }')"
    local_value="$(echo "$line" | awk '{ print $2 }')"

    name="$(echo "$name" | head -c "$indent_count")$local_name"
    value="$(echo "$value" | head -n "$indent_count" && echo "$local_value")"
    value_concat="$(echo "$value" | tr -d '\n')"

    echo "$name $value_concat" >> "$outfile"
done <<< "$config"
