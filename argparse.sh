#!/bin/bash

# Skeleton for parsing command line arguments in bash scripts

while (($# > 0)); do
    arg=$1
    if [[ $arg == '-' ]]; then
        shift
        break
    fi
    if [[ $arg =~ --[^-].* ]]; then
        arg="${arg: 2}"
        echo "Long option '$arg'"
        case ${arg} in
            size ) 
                shift; size="$1" ;;
            time ) 
                shift; time="$1" ;;
            * ) echo "Unknown long option '$arg'" ;;
        esac
    elif [[ $arg =~ -[^-]* ]]; then
        arg="${arg: 1}"
        echo "Short option ${arg}"
        for (( i = 0; i < ${#arg}; i++ )); do
            letter=${arg:i:1}
            case $letter in
                t|T)
                    shift; time="$1";;
                s|S)
                    shift; size="$1";;
                *) echo "Unknown short option '$letter'"
            esac
        done
    else
        echo "Positional argument: '$arg'"
        pos+=($arg)
    fi
    shift 
done
pos+=($@)

echo "size: $size"
echo "time: $time"
echo "positional: ${pos[@]}"
# for arg in ${pos[@]}; do
    # echo $arg
# done
