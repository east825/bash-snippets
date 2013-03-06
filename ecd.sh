#!/bin/bash
dirlist=($(pwd))
MAX_DIRLIST_LENGTH=5
# set -x

ecd_cd() {
    cd $@
    # first reoreder all other directories in list
    if (( ${#dirlist[@]} < MAX_DIRLIST_LENGTH)); then
        dirlist+=("$(pwd)")
    else
        for ((i = $MAX_DIRLIST_LENGTH - 1; i > 0; i--)); do
            dirlist[i]="${dirlist[i-1]}"
        done
        dirlist[0]="$(pwd)"
    fi
}

ecd_list() {
    local name
    # show all directroies
    for ((i = 0; i < ${#dirlist[@]}; i++)); do
        # if name is too long, truncate it
        if (( ${#dirlist[i]} > 70 )); then
            # take first 27 elements and last 40
            name="${dirlist[i]:0:27}...${dirlist[i]: -40}"
        else
            name="${dirlist[i]}"
        fi
        printf " %02d | %-70s\n" $i $name
    done
    # accept choice
    read -p "enter directory number: "
    # just <Enter> shouldn't be interpreted as error
    if [[ -n $REPLY ]]; then
        # check correct input: input is number and 0 < input <= MAX_DIRLIST_LENGTH
        if [[ $REPLY =~ ^[0-9]+$ ]] && (( REPLY >= 0 && REPLY < ${#dirlist[@]} )); then
            ecd_cd "${dirlist[REPLY]}"
        else
            echo "invalid choice" >&2
        fi
    fi
}
ecd() {
    if [[ "$1" == "-l" ]]; then
        ecd_list
    else
        ecd_cd $@
    fi
}
# set +x
