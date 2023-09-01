cmake_minimum_required(VERSION 3.1.0)
project(retro)

add_library(
    retro
    MODULE
        ./retro_intf.c
        ./dlfcn.c
)

if(ANDROID)
    find_library(log-lib log)
    find_library(dl-lib NAMES libdl.so dl)
    target_link_libraries(retro ${log-lib} ${dl-lib})
endif()

if(LOVR)
    list(APPEND LOVR_PLUGIN_TARGETS retro)
endif()
