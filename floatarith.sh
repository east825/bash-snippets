#!/bin/bash

# Condition and arithmetic experssions evaluation with floating point 
# numbers for shell scripts (using bc for actual computations)

fcond() {
    res=$(bc -q <<< "$*" 2>/dev/null)
    # echo "res='$res'"
    (( res != 0 ))
    return $?
}

fexpr() {
    bc -q <<< "$*" 2>/dev/null
}
exit 0

if fcond 0.1 '>' 21; then
    echo True
else
    echo False
fi

for ((i = 0; i < 10; i++)); do
    echo $(fexpr "$i + 1")
done
