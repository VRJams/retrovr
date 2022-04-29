# RetroVR


## Building

The project is still at an early stage so expect to find idiosyncrasies along
the way. In order to build this project, you must install the Android SDK/NDK
and set-up the ANDROID_HOME environment variable.

After checking out the repository, run the following command (only once):

    $ ./etc/init-repository.sh

The command will recursively checkout all sub-repositories and initialize some
symlinks. Eventually, this will not be necessary but it is the easiest thing to
do at this stage.


## Organization

    ./etc           contains general scripts and manifests
    ./external      contains sub-repositories (e.g., lovr)
    ./plugins       contains lovr plugins (e.g., libretro)
    ./project       contains main source of the project and its assets
