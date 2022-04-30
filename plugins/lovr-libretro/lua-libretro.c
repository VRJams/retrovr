#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include <assert.h>
#include <stdlib.h>

#include "log.h"
#include "retro_intf.h"

/// Destroy the current libretro core allocated objects.
static int
lret_destroy(lua_State* L)
{
    // TODO(sgosselin): implement.
    LOG("%s: called\n", __func__);

    return 0;
}

/// Initialize the libretro core.
static int
lret_init(lua_State* L)
{
    // TODO(sgosselin): implement.
    LOG("%s: called\n", __func__);

    return 0;
}

/// Run the current libretro core once.
static int
lret_run_once(lua_State* L)
{
    // TODO(sgosselin): implement.
    LOG("%s: called\n", __func__);

    return 0;
}

/// Set the memory destination of the libretro core video buffer.
static int
lret_set_video_buffer(lua_State* L)
{
    // TODO(sgosselin): implement.
    LOG("%s: called\n", __func__);

    return 0;
}

static const luaL_Reg lret_api[] = {
    { "init", lret_init },
    { "run_once", lret_run_once },
    { "set_video_buffer", lret_set_video_buffer },
    { NULL, NULL },
};

int
luaopen_libretro(lua_State* L)
{
    LOG("%s: called\n", __func__);

    lua_newtable(L);
    luaL_register(L, NULL, lret_api);

    // add sentinel userdata to free buffers on GC
    lua_newuserdata(L, sizeof(void*));
    lua_createtable(L, 0, 1);
    lua_pushcfunction(L, lret_destroy);
    lua_setfield(L, -2, "__gc");
    lua_setmetatable(L, -2);
    lua_setfield(L, -2, "");

    return 1;
}
