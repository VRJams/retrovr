cmake_minimum_required(VERSION 3.1)
project(lua-libretro)

add_library(lua-libretro
    MODULE
    lua-libretro.c
    retro_intf.c
)

set_target_properties(lua-libretro PROPERTIES PREFIX "")

target_include_directories(lua-libretro
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/include
)

# if we are on Android, use liblog for logging into logcat instead of stdout
if(ANDROID)
    find_library(log-lib log)
    find_library(dl-lib NAMES libdl.so dl)
    target_link_libraries(lua-libretro ${log-lib} ${dl-lib})
endif()

if(LOVR)
	set(LOVR_PLUGIN_TARGETS lua-libretro lua-libretro)
endif()
