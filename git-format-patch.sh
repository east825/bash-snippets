#!/usr/bin/env bash
set -e

PROG="$(basename $0)"
USAGE="\
Usage: 
    $PROG SCENARIO
    $PROG [--log|--diff|--patch] [--branch BRANCH] [--no-stdout] FILE...
"
do_patch() {
    git format-patch ${STDOUT:+--stdout} -M90% --binary ${BRANCH} -- "${@}"
}

do_log() {
    git log ${BRANCH}.. -- "${@}"
}

do_diff() {
    # --src-prefix='a/community/' --dst-prefix='b/community/'
    git diff -M90% --binary  "${BRANCH}" -- "${@}"
}

# default settings
export CMD=do_patch
export BRANCH=master
export STDOUT=true

while (( $# > 0 )); do
    arg="$1"
    if [[ $arg =~ ^- ]]; then
        case $1 in
            --log|-l) 
                CMD=do_log ;;
            --diff|-l) 
                CMD=do_diff ;;
            --patch|-p) 
                CMD=do_patch ;;
            --no-stdout)
                STDOUT= ;;
            --branch|-b)
                shift; BRANCH="$1" ;;
            *)
                echo "Unknown option '$arg'" >&2 ;;
        esac
        shift
    else
        break
    fi
done

if (( $# == 0 )); then
    echo "Files affected or scenario not specified" >&2
    echo "$USAGE" >&2
    exit 1
fi

case "$1" in
    jira)
        FILES="\
            plugins/tasks/jira-connector \
            plugins/tasks/tasks-core/src/icons \
            plugins/tasks/tasks-core/src/META-INF/plugin.xml \
            plugins/tasks/tasks-core/src/com/intellij/tasks/jira \
            plugins/tasks/tasks-tests/test/com/intellij/tasks/jira/jql \
            plugins/tasks/tasks-tests/testData/jira \
            plugins/tasks/tasks-core/tasks-core.iml \
            plugins/tasks/tasks-tests/tasks-tests.iml \
            community-main.iml \
            plugins/github/github.iml \
            .idea/modules.xml"
        if [[ $CMD == do_patch && -n "$STDOUT" ]]; then
            $CMD $FILES > jira.patch
        else
            $CMD $FILES
        fi
        ;;
    *) $CMD "${@}" ;;
esac

