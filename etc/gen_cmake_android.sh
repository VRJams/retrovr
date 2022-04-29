#!/usr/bin/env bash
#
# NOTE: There are paths hardcoded here that shouldn't but this project is
#       still in its early phase. This script also assumes Quest 2 as a
#       target and might not work well for other Android based headsets.

# TODO(sgosselin): we should not hardcode those paths.
PATH_KEYSTORE="${HOME}/.keystore/android_debug.keystore"
PATH_KEYSTORE_PASS="${PATH_KEYSTORE}.password"

if [[ "$#" -ne 1 ]];
then
    echo "usage: $0 [src_dir]"
    exit 1
fi

if [[ ! -d "$1/.git" ]];
then
    echo "Error, src_dir should be the root of the repository"
    exit 1
fi

if [[ -z "${ANDROID_HOME}" ]];
then
    echo "Error, environment variable missing: ANDROID_HOME"
    exit 1
fi

if [[ -z "${HOME}" ]];
then
    echo "Error, environment variable missing: HOME"
    exit 1
fi

if [[ ! -f "${PATH_KEYSTORE}" ]];
then
    echo "Error, missing keystore file: ${PATH_KEYSTORE}"
    exit 1
fi

if [[ ! -f "${PATH_KEYSTORE_PASS}" ]];
then
    echo "Error, missing keystore password file: ${PATH_KEYSTORE_PASS}"
    exit 1
fi

REPO_ROOT=$(realpath $1)

# TODO(sgosselin): add the project scripts and assets with ANDROID_ASSETS.
cmake \
    -D LOVR_USE_VRAPI=ON \
    -D CMAKE_TOOLCHAIN_FILE=$ANDROID_HOME/ndk-bundle/build/cmake/android.toolchain.cmake \
    -D ANDROID_SDK=$ANDROID_HOME \
    -D ANDROID_ABI=arm64-v8a \
    -D ANDROID_NATIVE_API_LEVEL=29 \
    -D ANDROID_BUILD_TOOLS_VERSION=30.0.1 \
    -D ANDROID_KEYSTORE=$HOME/.keystore/android_debug.keystore \
    -D ANDROID_KEYSTORE_PASS=file:$HOME/.keystore/android_debug.keystore.password \
    -D ANDROID_MANIFEST=${REPO_ROOT}/etc/AndroidManifest.xml \
    $1
