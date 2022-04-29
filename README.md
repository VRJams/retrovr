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


## Organization

    ./etc           contains general scripts and manifests
    ./external      contains sub-repositories (e.g., lovr)
    ./plugins       contains lovr plugins (e.g., libretro)
    ./project       contains main source of the project and its assets
