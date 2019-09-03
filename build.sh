#!/bin/bash

cd "`dirname $0`"

INSTALL_DIR="`pwd`/_build"

if ! cmake > /dev/null 2>&1; then
  export PATH="`pwd`/_build/cmake/bin:$PATH"
fi

set -ex

MODULE_PATH="`pwd`/cmake"

mkdir -p build
pushd build
  cmake .. \
    -DOPENSSL_ROOT_DIR="$INSTALL_DIR/boringssl" \
    -DCMAKE_PREFIX_PATH="$INSTALL_DIR/grpc;$INSTALL_DIR/cares;$INSTALL_DIR/protobuf;$INSTALL_DIR/zlib" \
    -DCLI11_ROOT_DIR="$INSTALL_DIR/CLI11" \
    -DCMAKE_MODULE_PATH=$MODULE_PATH
  make "$@" -j4
popd
