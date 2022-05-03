cmake_minimum_required(VERSION 3.1.0)
project(retro)

add_library(
    retro
    MODULE
        ./retro_intf.c
)

if(LOVR)
    list(APPEND LOVR_PLUGIN_TARGETS retro)
endif()
