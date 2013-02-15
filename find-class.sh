#!/bin/bash
# @author Mikhail Golubev <mikhail.golubev@oracle.com>

# Parse supplied arguments
if (( $# == 0 )); then
    echo "Usage: $0 [path] class-name" >&2
    exit 1
elif (( $# == 1)); then
    class_name=$1
else 
    path=$1
    class_name=$2
fi

# Verify that directory exists
path=${path:-"${JAVA_HOME}/jre/lib"}
if ! [[ -d $path ]]; then
    echo "directory $path does not exist" >&2
    exit 1
fi

# I assume that class contained in package will be given as 
# [package1. ...]class_name
# To match it in filesystem or jar archive dots in path should be
# converted to slashes
path_to_class=${class_name//.//}

# At first trying to find it as .java or .class file in directo
for file in "$( find $path -type f -name "*.class" -o -name "*.java" )"; do
    # remove .jar/.class extension
    file=${file%%.jar}
    file=${file%%.class}
    if [[ $file =~ ${path_to_class}$ ]]; then
        echo "Found not jar packed .java/.class file"
        echo -e "${file}\n"
    fi
done

# Then take a look at jar files
for jar_file in $( find $path -type f -name "*.jar" ); do
    found_classes=""; i=0
    for class in $(jar -tf $jar_file); do
        if [[ $class =~ ${path_to_class}\.class$ ]]; then
            found_classes[i++]="${class}"
        fi
    done
    if [[ -n ${found_classes} ]]; then
        echo -e "In ${jar_file} found:"
        for class in "${found_classes[@]}"; do
            echo "$class"
        done
        echo ""
    fi
done

