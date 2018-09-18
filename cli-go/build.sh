#!/bin/bash

function abspath() {
    # generate absolute path from relative path
    # $1     : relative filename
    # return : absolute path
    if [ -d "$1" ]; then
        # dir
        (cd "$1"; pwd)
    elif [ -f "$1" ]; then
        # file
        if [[ $1 = /* ]]; then
            echo "$1"
        elif [[ $1 == */* ]]; then
            echo "$(cd "${1%/*}"; pwd)/${1##*/}"
        else
            echo "$(pwd)/$1"
        fi
    fi
}

project_root=$(abspath $(dirname $0))
burrow_root=$(abspath $(dirname $0)/../burrow)
common_root=$(abspath $(dirname $0)/../common)

export GOPATH=$project_root:$burrow_root:$common_root
cd $project_root/src/seth_cli/cli
go build -o $project_root/bin/seth
