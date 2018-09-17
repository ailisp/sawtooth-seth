FROM ubuntu:xenial

ENV GOPATH=/project/sawtooth-seth/cli-go
ENV PATH=$PATH:/project/sawtooth-seth/cli-go/bin:/project/sawtooth-seth/bin:/usr/lib/go-1.9/bin

RUN \
 if [ ! -z $HTTP_PROXY ] && [ -z $http_proxy ]; then \
  http_proxy=$HTTP_PROXY; \
 fi; \
 if [ ! -z $HTTPS_PROXY ] && [ -z $https_proxy ]; then \
  https_proxy=$HTTPS_PROXY; \
 fi

RUN (apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 8AA7AF1F1091A5FD \
 || apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 8AA7AF1F1091A5FD) \
 && echo 'deb http://repo.sawtooth.me/ubuntu/1.0/stable xenial universe' >> /etc/apt/sources.list \
 && apt-get update \
 && apt-get install -y -q \
    curl \
    gcc \
    git \
    golang-1.9-go \
    libssl-dev \
    libzmq3-dev \
    openssl \
    pkg-config \
    python3 \
    python3-grpcio-tools=1.1.3-1 \
    python3-sawtooth-cli \
    software-properties-common \
    unzip \
 && add-apt-repository -k hkp://p80.pool.sks-keyservers.net:80 ppa:ethereum/ethereum \
 && apt-get update \
 && apt-get install -y -q \
    solc \
 && curl -s -S -o /tmp/setup-node.sh https://deb.nodesource.com/setup_6.x \
 && chmod 755 /tmp/setup-node.sh \
 && /tmp/setup-node.sh \
 && apt-get install nodejs -y -q \
 && rm /tmp/setup-node.sh \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN \
 if [ ! -z $http_proxy ]; then \
  npm config set proxy $http_proxy; \
  git config --global http.proxy $http_proxy; \
 fi; \
 if [ ! -z $https_proxy ]; then \
  npm config set https-proxy $https_proxy; \
  git config --global https.proxy $https_proxy; \
 fi

RUN git config --global url."https://".insteadOf git://

RUN go get -u \
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

RUN go get github.com/hyperledger/sawtooth-sdk-go \
 && cd $GOPATH/src/github.com/hyperledger/sawtooth-sdk-go \
 && go generate

RUN npm install \
    ethereumjs-abi \
    web3

RUN curl -OLsS https://github.com/google/protobuf/releases/download/v3.5.1/protoc-3.5.1-linux-x86_64.zip \
 && unzip protoc-3.5.1-linux-x86_64.zip -d protoc3 \
 && rm protoc-3.5.1-linux-x86_64.zip

RUN curl https://sh.rustup.rs -sSf > /usr/bin/rustup-init \
 && chmod +x /usr/bin/rustup-init \
 && rustup-init -y

ENV PATH=$PATH:/project/sawtooth-seth/bin:/root/.cargo/bin:/protoc3/bin \
    CARGO_INCREMENTAL=0

WORKDIR /project/sawtooth-seth/rpc

COPY bin/ /project/sawtooth-seth/bin
COPY protos/ /project/sawtooth-seth/protos
COPY rpc/ /project/sawtooth-seth/rpc
COPY tests/ /project/sawtooth-seth/tests

RUN cargo build && cp ./target/debug/rpc /project/sawtooth-seth/bin/seth-rpc

COPY . /project/sawtooth-seth

RUN seth-protogen go

WORKDIR $GOPATH/src/seth_cli/cli
ENV GOPATH=$GOPATH:/project/sawtooth-seth/burrow:/project/sawtooth-seth/common
RUN go build -o /project/sawtooth-seth/cli-go/bin/seth
