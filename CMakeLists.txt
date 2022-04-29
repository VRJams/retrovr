project(retrovr)
cmake_minimum_required(VERSION 3.1)

# The LOVR build system builds the engine, plugins and packages
# everything into an APK (for Android targets). As such, we can
# mostly rely on its build system to build RetroVR.
add_subdirectory(external/lovr)
