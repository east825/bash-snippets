#!/bin/bash
export ECD_DIRLIST
ECD_DIRLIST_LENGTH=5
# set -x

ecd(){
    # first reoreder all other directories in list
    for ((i=$ECD_DIRLIST_LENGTH - 1; i > 0; i--))
    do
        ECD_DIRLIST[i]=${ECD_DIRLIST[i-1]}
    done

    cd $1
    ECD_DIRLIST[0]=$(pwd)
}

ecdlist(){
    local name
    # show all directroies
    for ((i=0; i < $ECD_DIRLIST_LENGTH; i++))
    do
        # if name is too long, truncate it
        if (( ${#ECD_DIRLIST[i]} > 70 ));
        then
            # take first 27 elements and last 40
            name="${ECD_DIRLIST[i]:0:27}...${ECD_DIRLIST[i]: -40}"
        else
            name="${ECD_DIRLIST[i]}"
        fi
        printf " %02d | %-70s\n" $((i+1)) $name
    done
    # accept choice
    read -p "enter directory number: "
    # just <Enter> shouldn't be interpreted as error
    if [[ -n $REPLY ]];
    then
        # check correct input: input is number and 0 < input <= ECD_DIRLIST_LENGTH
        if [[ $REPLY =~ ^[0-9]+$ ]] && (( $REPLY <= ECD_DIRLIST_LENGTH && $REPLY > 0));
        then
            # if element isn't empty
            if [[ -n ${ECD_DIRLIST[REPLY-1]} ]];
            then 
                ecd ${ECD_DIRLIST[REPLY-1]}
            else
                echo "entry is empty" >&2
            fi
        else
            echo "incorrect input" >&2
        fi
    fi
}

# set +x
