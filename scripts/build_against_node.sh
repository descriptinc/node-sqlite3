#!/usr/bin/env bash

set -e -u

echo "building binaries for publishing"
V=1 npm install --build-from-source
nm lib/binding/*/node_sqlite3.node | grep "GLIBCXX_" | c++filt  || true
nm lib/binding/*/node_sqlite3.node | grep "GLIBC_" | c++filt || true
npm test
 
if [ ! -z "${TARGET_ARCH:-}" ]; then
  TARGET_ARCH_ARG="--target_arch=${TARGET_ARCH}"
else
  TARGET_ARCH_ARG="--target_arch=x64"
fi

npm exec node-pre-gyp rebuild ${TARGET_ARCH_ARG}
