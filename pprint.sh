#!/bin/bash

IFS=':' 
for chunk in $( printenv $1 ); do
    echo "$chunk"
done
