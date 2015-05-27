#!/usr/bin/env bash

DEV_IDEA_HOME="${DEV_IDEA_HOME:-$(pwd)}"

while read path; do
    cd "$path"
    CMD_OUT=$( "$@" 2>&1 )
    echo -e "\n> $path [$( (($? == 0)) && echo ok || echo failed )]"
    if [[ -n "$CMD_OUT" ]]; then
        echo "$CMD_OUT"
    fi
    cd - &>/dev/null
done < <(find "$DEV_IDEA_HOME" -maxdepth 3 -type d -exec test -d '{}/.git' ';' -print)

