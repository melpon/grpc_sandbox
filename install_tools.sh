#!/bin/bash

set -ex

CMAKE_VERSION="3.13.2"
GRPC_VERSION="1.22.0"
CLI11_VERSION="1.8.0"

BUILD_DIR="`pwd`/_build"
INSTALL_DIR="`pwd`/_build"

CMAKE_DIR="`pwd`/_build"
GRPC_SOURCE_DIR="`pwd`/_build/grpc-source"
GRPC_VERSION_FILE="$INSTALL_DIR/grpc.version"
CLI11_VERSION_FILE="$INSTALL_DIR/cli11.version"

CMAKE_BUILD_TYPE=Release

GRPC_CHANGED=0
CLI11_CHANGED=0

if [ ! -e $GRPC_VERSION_FILE -o "$GRPC_VERSION" != "`cat $GRPC_VERSION_FILE`" ]; then
  GRPC_CHANGED=1
fi

if [ ! -e $CLI11_VERSION_FILE -o "$CLI11_VERSION" != "`cat $CLI11_VERSION_FILE`" ]; then
  CLI11_CHANGED=1
fi

# gRPC のソース
if [ ! -e $GRPC_SOURCE_DIR ]; then
  git clone https://github.com/grpc/grpc.git $GRPC_SOURCE_DIR
fi
pushd $GRPC_SOURCE_DIR
  git fetch
  git reset --hard v$GRPC_VERSION
  git submodule update -i --recursive
popd

# cmake
if ! cmake > /dev/null 2>&1; then
  if [ ! -e $CMAKE_DIR/cmake/bin/cmake ]; then
    pushd $CMAKE_DIR
      wget https://github.com/Kitware/CMake/releases/download/v$CMAKE_VERSION/cmake-$CMAKE_VERSION.tar.gz
      tar xf cmake-$CMAKE_VERSION.tar.gz
      mv cmake-$CMAKE_VERSION cmake-source
      pushd cmake-source
        ./configure --system-curl --prefix=`pwd`/../cmake
        make -j4
        make install
      popd
    popd
  fi
  export PATH=$CMAKE_DIR/cmake/bin:$PATH
fi

# boringssl (cmake)
if [ $GRPC_CHANGED -eq 1 -o ! -e $INSTALL_DIR/boringssl/lib/libssl.a ]; then
  mkdir -p $BUILD_DIR/boringssl-build
  pushd $BUILD_DIR/boringssl-build
    cmake $GRPC_SOURCE_DIR/third_party/boringssl -DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR/boringssl $CMAKE_TOOLCHAIN_FILE
    make -j4
    # make install はインストールするものが無いって言われるので
    # 手動でインストールする
    mkdir -p $INSTALL_DIR/boringssl/lib
    cp ssl/libssl.a crypto/libcrypto.a $INSTALL_DIR/boringssl/lib
    mkdir -p $INSTALL_DIR/boringssl/include
    rm -rf $INSTALL_DIR/boringssl/include/openssl
    cp -r $GRPC_SOURCE_DIR/third_party/boringssl/include/openssl $INSTALL_DIR/boringssl/include/openssl
  popd
fi

# zlib (pkgconfig)
if [ $GRPC_CHANGED -eq 1 -o ! -e $INSTALL_DIR/zlib/lib/libz.a ]; then
  pushd $GRPC_SOURCE_DIR/third_party/zlib
    make clean || true

    ./configure --prefix=$INSTALL_DIR/zlib --static
    make -j4
    make install
    make clean
  popd
fi

# cares (cmake)
if [ $GRPC_CHANGED -eq 1 -o ! -e $INSTALL_DIR/cares/lib/libcares_static.a ]; then
  mkdir -p $BUILD_DIR/cares-build
  pushd $BUILD_DIR/cares-build
    cmake $GRPC_SOURCE_DIR/third_party/cares/cares -DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR/cares -DCARES_STATIC=ON -DCARES_SHARED=OFF $CMAKE_TOOLCHAIN_FILE
    make -j4
    make install
  popd
fi

# protobuf (cmake)
if [ $GRPC_CHANGED -eq 1 -o ! -e $INSTALL_DIR/protobuf/lib/libprotobuf.a ]; then
  mkdir -p $BUILD_DIR/protobuf-build
  pushd $BUILD_DIR/protobuf-build
    cmake $GRPC_SOURCE_DIR/third_party/protobuf/cmake \
      -DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE \
      -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR/protobuf \
      -DCMAKE_PREFIX_PATH="$INSTALL_DIR/zlib" \
      -Dprotobuf_BUILD_TESTS=OFF \
      -DCMAKE_FIND_DEBUG_MODE=1 \
      $CMAKE_TOOLCHAIN_FILE
    make -j4
    make install
  popd
fi

# grpc (cmake)
if [ $GRPC_CHANGED -eq 1 -o ! -e $INSTALL_DIR/grpc/lib/libgrpc++_unsecure.a ]; then
  mkdir -p $BUILD_DIR/grpc-build
  pushd $BUILD_DIR/grpc-build
    cmake $GRPC_SOURCE_DIR \
      -DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE \
      -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR/grpc \
      -DgRPC_BUILD_TESTS=ON \
      -DgRPC_ZLIB_PROVIDER=package \
      -DgRPC_CARES_PROVIDER=package \
      -DgRPC_PROTOBUF_PROVIDER=package \
      -DgRPC_SSL_PROVIDER=package \
      -DgRPC_BUILD_CSHARP_EXT=OFF \
      -DOPENSSL_ROOT_DIR=$INSTALL_DIR/boringssl \
      -DCMAKE_PREFIX_PATH="$INSTALL_DIR/cares;$INSTALL_DIR/protobuf;$INSTALL_DIR/zlib" \
      -DCMAKE_FIND_DEBUG_MODE=1 \
      -DBENCHMARK_ENABLE_TESTING=0 \
      $GRPC_CMAKE_OPTS \
      $CMAKE_TOOLCHAIN_FILE
    make -j4
    make install
  popd
  cp $BUILD_DIR/grpc-build/grpc_cli ./
fi

echo $GRPC_VERSION > $GRPC_VERSION_FILE

# CLI11
if [ $CLI11_CHANGED -eq 1 -o  ! -e $INSTALL_DIR/CLI11/include ]; then
  rm -rf $INSTALL_DIR/CLI11
  git clone --branch v$CLI11_VERSION --depth 1 https://github.com/CLIUtils/CLI11.git $INSTALL_DIR/CLI11
fi
echo $CLI11_VERSION > $CLI11_VERSION_FILE
