#!/bin/bash

set -e

if [[ "$1" == "-h" ]]; then
    echo "usage: $0 src-dir [dst-dir]"
    exit 1
fi

src="${1:? sources dir not set}"
dst="${2:-.}"

src="$(readlink -f $src)"

find "$src" -type f -executable | while read path; do
    target="$path"
    linkname="${dst}/$(basename $path)"
    ln -s "$target" "$linkname" 
    echo "$linkname -> $target"
done
