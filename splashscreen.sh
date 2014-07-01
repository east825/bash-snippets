#!/usr/bin/env bash
set -e

repeat() {
    for ((i=0; i < "$1"; i++)); do
        echo -en "$2"
    done
}

TERM_WIDTH="$(tput cols)"
TERM_HEIGHT="$(tput lines)"

clear

lines_before=$(( (TERM_HEIGHT - $#) / 2 ))
repeat $lines_before '\n'
for line in "$@"; do
    repeat $(( (TERM_WIDTH - ${#line}) / 2 )) ' '
    echo "$line"
done
repeat $(( TERM_HEIGHT - lines_before - $# )) '\n'

read && clear
