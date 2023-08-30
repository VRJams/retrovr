# RetroVR

**This for was created to continue the work from the upstream repo**

RetroVR aims to integrate the [LibRetro](https://libretro.com) system inside the [LOVR](https://lovr.org) VR framework, aiming for now specifically at creating compatible VR Light guns.

**This project is using version 0.16 of LOVR**

## Building

To better understand the compilation process, consult the [relevant LOVR docs](https://lovr.org/docs/v0.15.0/Compiling)

### Android

You will have to install the [Android SDK and NDK](https://developer.android.com/studio/). 
The Command Line Tools are sufficient.

TO aid in building there is a `gen_cmake_android.sh` inside `etc\`.
To use it, set up the `ANDROID_HOME` environment variable pointing to your SDK installation location.
It also expects you to have your Java keystore and password file in `${HOME}/.keystore/android_debug.keystore`. 
When ready, run these from the root folder of the repo:

    $ mkdir build
    $ cd build
    $ ../etc/gen_cmake_android.sh ..
    $ make

The resulting APK is located in `build/deps/lovr/lovr.apk`. 

### Linux

The project can also be compiled on Linux and other desktops.

Linux is our second target for compilation after Android, others might not be tested as thoroughly.

Ensure to have a C compiler and CMake installed, then clone the repository, then:

    $ mkdir build
    $ cd build
    $ cmake ..
    $ cmake --build .

This will compile the LOVR executable and needed libraries to the `build/bin` folder.

## Running

For now, we're focusing on the PCSX ReARMed core, and using the Point Blank PSX game as a starting point.
These parameters are coded in the `src/main.lua` file if you want to test other cores and games.

The cores can be downloaded from the [LibRetro build bot](https://buildbot.libretro.com/).
Here select Stable or Nightly, then find your operating system and then the correct architecture. 

Oculus uses arm64-v8a, while desktops are likely x86-64.

### Quest 2

Once the APK is installed, you need to upload both the core and the project.
The core will remain there, so unless you need to change version you only need to do this once.

These methods use the ADB console, which you probably have already installed to work with LOVR before on your headset.

The games are expected to be placed in `src/games`.
The src folder can be pushed to the usual LOVR project folder at `/sdcard/Android/data/retrovr.app/files`.

    adb push --sync src/. /sdcard/Android/data/retrovr.app/files

The Core must be put specifically in the `/data/data/retrovr.app` folder. This is not normally accessible via ADB, but it can be accessed in a few steps.

1. Push the core files to an available folder, like the project folder
    
        adb push --sync src/cores/. /sdcard/Android/data/retrovr.app/files/cores

2. Now use `run-as` to impersonate the RetroVR app
        
        adb shell run-as retrovr.app

3. Now move the files from the project folder to the target folder
        
        cp /sdcard/Android/data/retrovr.app/files/cores/pcsx_rearmed_libretro_android.so /data/data/retrovr.app/

The specific placement of the core is due to [Android's limitation](https://android-developers.googleblog.com/2016/06/improving-stability-with-private-cc.html) on [linking to dynamic libraries](https://linux.die.net/man/3/dlopen).

### Linux

Here files don't have the same limitations, and are expected to all be inside `src`.

Specifically, the cores in `src/cores` and the games in `src/games`.

Then, run `.build/bin/lovr --console ./src`

## Organization

    ./etc           contains general scripts and manifests
    ./deps          contains sub-repositories (e.g., lovr)
    ./plugins       contains lovr plugins (e.g., libretro)
    ./src           contains Lua code of the project and its assets
