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

npm install \
    ethereumjs-abi \
    web3

project_root=$(abspath $(dirname $0))
export GOPATH=$project_root

go get -u \
   github.com/btcsuite/btcd/btcec \
   github.com/golang/mock/gomock \
   github.com/golang/mock/mockgen \
   github.com/golang/protobuf/proto \
   github.com/golang/protobuf/protoc-gen-go \
   github.com/jessevdk/go-flags \
   github.com/pebbe/zmq4 \
   github.com/pelletier/go-toml \
   github.com/satori/go.uuid \
   golang.org/x/crypto/ssh/terminal

export PATH=$project_root:$PATH

bash -c "go get github.com/hyperledger/sawtooth-sdk-go \
           && cd $GOPATH/src/github.com/hyperledger/sawtooth-sdk-go \
           && go generate
"

${project_root}/../bin/seth-protogen go
