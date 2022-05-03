cmake_minimum_required(VERSION 3.1.0)
project(retro)

add_library(
    retro
    MODULE
        ./retro_intf.c
)

target_include_directories(
    retro
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/include
)

if(LOVR)
    list(APPEND LOVR_PLUGIN_TARGETS retro)
endif()
