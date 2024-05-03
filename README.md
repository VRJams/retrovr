# RetroVR

**This for was created to continue the work from the upstream repo**

RetroVR aims to integrate the [LibRetro](https://libretro.com) system inside the [LOVR](https://lovr.org) VR framework, aiming for now specifically at creating compatible VR Light guns.

**This project is using version 0.17.1 of LOVR**

## Running

For now, we're focusing on the PCSX ReARMed core, and using the Point Blank PSX game as a starting point.
These parameters are coded in the `src/main.lua` file if you want to test other cores and games.

The cores can be downloaded from the [LibRetro build bot](https://buildbot.libretro.com/).
Here select Stable or Nightly, then find your operating system and then the correct architecture. 

Oculus uses arm64-v8a, while desktops are likely x86-64.

### Windows & Linux

You can [build it yourself](#building) or Get the latest builds for [Windows](https://github.com/VRJams/retrovr/releases/tag/v0.0.0-win) and [Linux](https://github.com/octo-org/octo-repo/releases/latest) 

You will need to download the code from the repository, at least the `src` folder.

Then you'll need to place the cores and game files inside it.
Specifically, the cores in `src/cores` and the games in `src/games`.

Then, run `retrovr --console ./src` on Linux or `lovr.exe --console ./src` on Windows

### Quest 2
You can find the built APK in [our releases](https://github.com/octo-org/octo-repo/releases/latest).

Once the APK is installed, you need to upload both the core and the project to the headset.
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

## Building

To better understand the compilation process, consult the [relevant LOVR docs](https://lovr.org/docs/v0.15.0/Compiling)

### Using Docker

For building to Linux and Android, I suggest using my [Docker based solution](https://github.com/Udinanon/lovr-docker-builder). You still need to download the code, but compilation happens inside the container.

You still need to download and prepare the code, adapt the script, and pass the emulator cores to the Oculus, but no need to install SDKs or other libraries to compile


### Android

You will have to install the [Android SDK and NDK](https://developer.android.com/studio/). 
The Command Line Tools are sufficient.

First, clone the repository and all submodules:

    $ git clone https://github.com/VRJams/retrovr --recursive

To aid in building there is a `gen_cmake_android.sh` inside `etc\`.
To use it, set up the `ANDROID_HOME` environment variable pointing to your SDK installation location.
It also expects you to have your Java keystore and password file in `${HOME}/.keystore/android_debug.keystore`. 
When ready, run these from the root folder of the repo:

    $ mkdir build
    $ cd build
    $ ../etc/gen_cmake_android.sh ..
    $ make

The resulting APK is located in `build/deps/lovr/lovr.apk`. 

### Linux

Linux is our second target for compilation after Android, others might not be tested as thoroughly.

Ensure to have a C compiler and CMake installed

Then clone the repository
First, clone the repository and all submodules:

    $ git clone https://github.com/VRJams/retrovr --recursive

Then, from the root of the repo:

    $ mkdir build
    $ cd build
    $ cmake ..
    $ cmake --build .

This will compile the LOVR executable and needed libraries to the `build/bin` folder.

### Windows

Windows is a new target for us, so issues might still appear

For now, Windows code has some special needs and is therefore kept on a [separate branch](https://github.com/VRJams/retrovr/tree/windows)

You'll need Git, CMake and MSVC, the [Visual Studio Build Tools](https://visualstudio.microsoft.com/downloads/?q=build+tools) and the [Vulkan SDK](https://www.lunarg.com/vulkan-sdk/)

Then clone re repository on the Windows branch

First, clone the repository and all submodules:

    $ git clone --branch windows https://github.com/VRJams/retrovr --recursive

Then, from the root of the repo:

    $ mkdir build
    $ cd build
    $ cmake ..
    $ cmake --build .

The resulting file will be `build/deps/lovr/Debug/lovr.exe`. 


## Organization

    ./etc           contains general scripts and manifests
    ./deps          contains sub-repositories (e.g., lovr)
    ./plugins       contains lovr plugins (e.g., libretro)
    ./src           contains Lua code of the project and its assets, such as games

## Thanks

This work stems from the amazing work done by [sgosselin](https://github.com/sgosselin) on his [original repo](https://github.com/sgosselin/retrovr). 

His code is the true heart of this project and this would never have been possible without him 

Thanks also to the amazing LOVR community, which has helped us develop this and gave us a lot of support! 
Find us and them on their [Matrix](https://matrix.to/#/#community:lovr.org)