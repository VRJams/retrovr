#!/usr/bin/env bash

LOVR_PLUGIN_DIR=$(pwd)/external/lovr/plugins
if [[ ! -d ".git" ]];
then
    echo "usage: run this script at the root of the repository"
    exit 1
fi

# ensure all submodules are checked out.
git submodule update --init --recursive
if [[ $? -ne 0 ]];
then
    echo "error: updating submodules failed"
    exit 1
fi

# create the plugin directory if needed
if [[ ! -d ${LOVR_PLUGIN_DIR} ]];
then
    mkdir -p ${LOVR_PLUGIN_DIR}
fi

# symlink the various lovr plugins into the engine plugin directory so they
# are built with the engine without any additional target definitions.
LOVR_PLUGINS=(lovr-libretro)
for plugin in ${LOVR_PLUGINS[@]}
do
    src=$(pwd)/src/${plugin}
    dst=${LOVR_PLUGIN_DIR}/${plugin}

    if [[ -d ${src} && ! -d ${dst} ]]; then
        echo "info: creating symlink for '${plugin}'"
        ln -f -s ${src} ${LOVR_PLUGIN_DIR}/${plugin}
    fi
done
