#!/bin/bash

set -e

src="${1:? sorces dir not set}"
dst="${2:-.}"

src="$(readlink -f $src)"

find "$src" -type f -executable | while read path; do
    target="$path"
    linkname="${dst}/$(basename $path)"
    ln -s "$target" "$linkname" 
    echo "$linkname -> $target"
done
