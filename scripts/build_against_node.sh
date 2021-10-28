#!/usr/bin/env bash

source ~/.nvm/nvm.sh

set -e -u

echo "building binaries for publishing"
CFLAGS="${CFLAGS:-} -include $(pwd)/src/gcc-preinclude.h" CXXFLAGS="${CXXFLAGS:-} -include $(pwd)/src/gcc-preinclude.h" V=1 npm install --build-from-source  --clang=1
nm lib/binding/*/node_sqlite3.node | grep "GLIBCXX_" | c++filt  || true
nm lib/binding/*/node_sqlite3.node | grep "GLIBC_" | c++filt || true
npm test

if [ -z "${TARGET_ARCH}" ]; then
  TARGET_ARCH_ARG="--target_arch=${TARGET_ARCH}"
else
  TARGET_ARCH_ARG="--target_arch=x64"
fi

CFLAGS="${CFLAGS:-} -include $(pwd)/src/gcc-preinclude.h" CXXFLAGS="${CXXFLAGS:-} -include $(pwd)/src/gcc-preinclude.h" node-pre-gyp rebuild --clang=1 ${TARGET_ARCH_ARG}
