# RetroVR


## Building

The project is still at an early stage so expect to find idiosyncrasies along
the way. In order to build this project, you must install the Android SDK/NDK
and set-up the ANDROID_HOME environment variable. Run the following commands
after checking out the repository to build the APK.

    $ mkdir build; cd build
    $ ../etc/gen_cmake_android.sh ..
    $ make

The resulting APK is located in external/lovr/lovr.apk. The APK name will be
renamed in a future diff.


## Running

### Quest 2

As of right now, I am only testing Point Blank on PSX with the PCSX rearmed core.
As a matter of fact, it's hardcoded in project/main.lua. If you want to play with
something else you'll need to change this file.

Cores can be downloaded from the libretro nightly builds:
http://buildbot.libretro.com/nightly/android/latest/arm64-v8a/

Then `adb push` the core and game into the application apk folder.


## Organization

    ./etc           contains general scripts and manifests
    ./external      contains sub-repositories (e.g., lovr)
    ./plugins       contains lovr plugins (e.g., libretro)
    ./project       contains main source of the project and its assets
