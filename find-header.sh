#!/bin/bash
SHIFT="    "
set +x

dfs() {
    local regex="$1" prefix="$2" 
    # echo "prefix='$prefix', pattern='$regex'"
    for header in $(find . -name "*.h" | xargs grep "$regex" | cut -d: -f1); do
        echo "$prefix$header"
        dfs "#include[ \t]*\"$(basename $header)\"" "$prefix$SHIFT" 
    done
}

name="$1"
echo "Searching for '$name'"
dfs "$name" 
