#!/usr/bin/env bash

set -e
# set -x

version_compare() {
    if [[ -z "$1" && -z "$2" ]]; then
        echo "0"; return
    elif [[ -z "$1" ]]; then
        echo "-1"; return
    elif [[ -z "$2" ]]; then
        echo "1"; return
    fi

    local major_first="$(cut -d. <<< $1 -f1)"
    local minor_first="$(cut -d. <<< $1 -f2)"
    local major_second="$(cut -d. <<< $2 -f1)"
    local minor_second="$(cut -d. <<< $2 -f2)"

    if (( major_first != major_second )); then
        echo "$(( major_first - major_second ))"
    else
        echo "$(( minor_first - minor_second ))"
    fi
}

version_extract() {
    echo "$( expr "$1" : '.*-\([[:digit:]]\+\.[[:digit:]]\+\).*' )"
}

version_installed() {
    local version="$(cat "${1}/build.txt" 2> /dev/null)"
    echo "$(version_extract $version)"
}

install() {
    # set -x

    local dest="$1"
    local archive=${2}

    info "Moving ${dest} to ${dest}.stable..."
    rm -rf "${dest}.stable"
    mv -Tf "$dest" "${dest}.stable" || true
    info "Extracting ${archive}..."
    rm -rf _extracted
    mkdir _extracted
    tar xzf "$archive" -C _extracted
    info "Moving $(ls _extracted) to ${dest}..."
    mv -Tf _extracted/* "$dest"
    rm -rf _extracted
}

info() {
    echo ">>> $1"
}


# Where all software not from repositories goes
SOFTWARE_HOME="/usr/local/software"

cd "$SOFTWARE_HOME"
for file_name in $(ls); do
    VERSION=$( version_extract "$file_name" )
    if [[ -n "$VERSION" ]]; then
        case "$file_name" in
            ideaIU-*.tar.gz) 
                if (( $(version_compare "$VERSION" "$MAX_IDEA_IU_VERSION") > 0 )); then
                    MAX_IDEA_IU_VERSION="$VERSION"
                fi
                ;;
            ideaIC-*.tar.gz)
                if (( $(version_compare "$VERSION" "$MAX_IDEA_IC_VERSION") > 0 )); then
                    MAX_IDEA_IC_VERSION="$VERSION"
                fi
                ;;
            pycharmPC-*.tar.gz)
                if (( $(version_compare "$VERSION" "$MAX_PYCHARM_PY_VERSION") > 0 )); then
                    MAX_PYCHARM_PY_VERSION="$VERSION"
                fi
                ;;
            pycharmPY-*.tar.gz)
                if (( $(version_compare "$VERSION" "$MAX_PYCHARM_PC_VERSION") > 0 )); then
                    MAX_PYCHARM_PC_VERSION="$VERSION"
                fi
                ;;
            *) continue ;;
        esac
    fi
done

info "Latest version of IDEA Ultimate is ${MAX_IDEA_IU_VERSION:-unknown}"
info "Latest version of IDEA Community is ${MAX_IDEA_IC_VERSION:-unknown}"
info "Latest version of PyCharm Ultimate is ${MAX_PYCHARM_PY_VERSION:-unknown}"
info "Latest version of PyCharm Community is ${MAX_PYCHARM_PC_VERSION:-unknown}"

if [[ -n "$MAX_IDEA_IU_VERSION" ]]; then
    if [[ "$(version_installed "idea-IU")" == "$MAX_IDEA_IU_VERSION" ]]; then
        info "IDEA Ultimate ${MAX_IDEA_IU_VERSION} already installed"
    else
        install "idea-IU" "ideaIU-${MAX_IDEA_IU_VERSION}.tar.gz"
    fi
fi

if [[ -n "$MAX_IDEA_IC_VERSION" ]]; then
    if [[ "$(version_installed "idea-IC")" == "$MAX_IDEA_IC_VERSION" ]]; then
        info "IDEA Community ${MAX_IDEA_IC_VERSION} already installed"
    else
        install "idea-IC" "ideaIC-${MAX_IDEA_IC_VERSION}.tar.gz"
    fi
fi

if [[ -n "$MAX_PYCHARM_PY_VERSION" ]]; then
    if [[ "$(version_installed "pycharm-PY")" == "$MAX_PYCHARM_PY_VERSION" ]]; then
        info "PyCharm Ultimate ${MAX_PYCHARM_PY_VERSION} already installed"
    else
        install "pycharm-PY" "pycharmPY-${MAX_PYCHARM_PY_VERSION}.tar.gz"
    fi
fi

if [[ -n "$MAX_PYCHARM_PC_VERSION" ]]; then
    if [[ "$(version_installed "pycharm-PC")" == "$MAX_PYCHARM_PC_VERSION" ]]; then
        info "PyCharm Community ${MAX_PYCHARM_PC_VERSION} already installed"
    else
        install "pycharm-PC" "pycharmPC-${MAX_PYCHARM_PC_VERSION}.tar.gz"
    fi
fi

