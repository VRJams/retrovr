cmake_minimum_required(VERSION 3.1)
project(lua-libretro)

add_library(lua-libretro
    MODULE
    lua-libretro.c
)

set_target_properties(lua-libretro PROPERTIES PREFIX "")

# if we are on Android, use liblog for logging into logcat instead of stdout
if(ANDROID)
    find_library(log-lib log)
    target_link_libraries(lua-libretro ${log-lib})
endif()

if(LOVR)
	set(LOVR_PLUGIN_TARGETS lua-libretro lua-libretro)
endif()
