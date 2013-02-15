#!/bin/bash

# shopt -s nocasematch
# read -p 'Enter [Y]es|[N]o: '
# # if (grep -iE '^(y|yes)$' <<< "$REPLY" &>/dev/null); then
# if [[ $REPLY =~ ^(y|yes)$ ]]; then
    # echo 'OK'
# else 
    # echo 'NO'
# fi

array=('foo' 'bar' 'quit')
select choice in "${array[@]}"; do
    echo $REPLY and $choice
    if [[ $choice == 'quit' ]]; then
        break
    fi
done
# array concatenation
array+=('spam' 'ham')
# explicit subscripts declaration
array+=([6]=elem6 [5]=elem5)
for item in "${array[@]}"; do
    echo $item
done
# array size
echo "${#array[@]}"
# size of first element
echo "${#array}"
# assossiative array
declare -A dict
dict['foo']=bar
dict['ham']=spam
for item in "${dict[@]}"; do
    echo $item
done

# set -e - terminate at first command with non-zero exit status
