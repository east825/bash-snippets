#!/usr/bin/env bash
set -e

USAGE="Usage: $(basename $0) load|store [FILE]"

COMMAND="${1:-store}"
PACKAGES_FILE="${2:-packages.list}"

if [[ "$COMMAND" == 'store' ]]; then
    echo "Storing list of installed packages in '$PACKAGES_FILE'..."
    dpkg --get-selections > "${PACKAGES_FILE}"
elif [[ "$COMMAND" == 'load' ]]; then
    echo "Loading list of installed packages from '$PACKAGES_FILE'..."
    sudo dpkg --clear-selections
    sudo dpkg --set-selections < "$PACKAGES_FILE"
    sudo apt-get install
else
    echo "Unknown commad $COMMAND" >&2
    echo "$USAGE" >&2
fi

# vim: ft=sh
