cmake_minimum_required(VERSION 3.1)
project(lua-libretro)

add_library(lua-libretro
    MODULE
    lua-libretro.c
)

set_target_properties(lua-libretro PROPERTIES PREFIX "")

if(LOVR)
	set(LOVR_PLUGIN_TARGETS lua-libretro lua-libretro)
endif()
