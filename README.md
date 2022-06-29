# Introduction

QEMU is a generic and open source machine & userspace emulator and
virtualizer.  

You can get more information about qemu through the following website:  
https://www.qemu.org/  

This project is based on qemu, mainly for some customized work on the 
simulation environment of some machines.  

## Qemu source code

The source code for qemu is taken from:  
Repository: https://gitlab.com/qemu-project/qemu.git  

## Patch

Folder "qemu_patch" contains all the patches.  

## Build
QEMU is multi-platform software intended to be buildable on all modern
Linux platforms, OS-X, Win32 (via the Mingw64 toolchain) and a variety
of other UNIX targets. The simple steps to build QEMU are:

    mkdir build
    cd build
    ../configure
    make

Additional information can also be found online via the QEMU website:

https://wiki.qemu.org/Hosts/Linux
https://wiki.qemu.org/Hosts/Mac
https://wiki.qemu.org/Hosts/W32


