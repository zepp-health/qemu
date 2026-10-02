# Zepp QEMU for Apple Silicon

Build Zepp's patched QEMU natively on Apple Silicon and use it with the Zepp OS Simulator, without Rosetta.

This community fork starts from [zepp-health/qemu](https://github.com/zepp-health/qemu), revision `4d3a92356109cf77e71e5958d16eb0dc1fabcece` (QEMU 6.2.50). The emulator source is unchanged; this fork adds build and local installation scripts. Zepp's machine, flash, input, display and interrupt patches are already applied in `qemu/`. Do not apply `qemu_patch/` again. The original introduction is preserved in [README.upstream.md](README.upstream.md).

## Why use this fork?

Zepp OS Simulator 2.1.2 has an ARM64 launcher but shipped an Intel `qemu-system-arm` in the installation tested here. Without Rosetta, firmware startup fails with `Bad CPU type in executable`. The executable name refers to the emulated guest, not the host CPU.

Stock Homebrew QEMU is not a drop-in replacement: version 11.1.2 failed to boot the tested Zepp firmware with a Cortex-M HardFault. Zepp's patched source built and booted successfully on ARM64.

## Prerequisites

Use native ARM64 macOS, Apple's Command Line Tools and native [Homebrew](https://brew.sh/). Install any missing dependencies:

```sh
xcode-select --install
brew install ninja pkgconf glib pixman
```

The build defaults to `/usr/bin/python3`. The tested version was 3.9.6; the bundled Meson is 0.59.3. Newer Python releases may require changes to this older build system. Set `QEMU_PYTHON=/absolute/path/to/python3` to choose a different interpreter. Homebrew's generic `qemu` package is not needed.

Obtain the macOS simulator separately from the [official Zepp OS simulator documentation](https://docs.zepp.com/docs/tools/simulator/). This repository does not package the Zepp simulator application or Zepp OS device firmware.

## Build

```sh
git clone https://github.com/MuhAssar/zepp-qemu-apple-silicon.git
cd zepp-qemu-apple-silicon
./scripts/build-macos-arm64.sh
```

The result is `build-output/qemu-system-arm`, stripped and ad hoc signed for local development. The script deletes its temporary build directory on success or failure. Source files remain intact. It refuses to overwrite an existing output; choose another path or remove the previous binary deliberately.

```sh
JOBS=6 QEMU_PYTHON=/usr/bin/python3 ./scripts/build-macos-arm64.sh /tmp/zepp-qemu-system-arm
```

The binary links Homebrew libraries dynamically. Keep those dependencies installed. It is not a self-contained binary for distribution to other Macs.

## Install into a separate simulator copy

Close all Zepp simulator instances before installing. Adjust the first argument if the vendor simulator is installed elsewhere:

```sh
./scripts/install-macos-arm64.sh /Applications/simulator.app
open "$HOME/Applications/ZeppSimulatorNative.app"
```

The script copies the vendor application to `$HOME/Applications/ZeppSimulatorNative.app`, replaces its QEMU, and signs the copy locally while preserving entitlements. The original application stays intact. The destination must not exist. To supply different paths:

```sh
./scripts/install-macos-arm64.sh /Applications/simulator.app \
  "$PWD/build-output/qemu-system-arm" "$HOME/Applications/ZeppSimulatorNative.app"
```

**The entire destination path must contain no whitespace.** The tested launcher constructs an unquoted internal `cd`; a path such as `Zepp Simulator Native.app` fails even when the outer `open` command is quoted. This installer checks the path before copying.

This is an ad hoc signed local development copy, not a notarized vendor release. The installer does not change global macOS security settings. If macOS prevents launching it, inspect the reported error before changing any security policy.

Then start app development from your Mini Program project:

```sh
zeus dev --target "Amazfit Bip Max"
```

Run one simulator instance at a time; the vendor and native copies may share cached device data and settings.

## Validation and limits

Observed on 2026-10-02 with macOS 27.0.1, Apple Clang 21, Python 3.9.6, Ninja 1.13.2, pkgconf 3.0.7, glib 2.90.0 and pixman 0.46.4:

- Native ARM64 build of QEMU 6.2.50, without emulator source changes.
- Zepp OS Simulator 2.1.2 started Amazfit Bip Max simulator firmware v1.0.0; firmware HTTP/WebSocket service started on port 7833.
- Zeus CLI 1.9.3 connected to port 7650, built and deployed the official Todo List sample for deviceSource `11206915`; app/page lifecycle callbacks ran.
- The installed application passed `codesign --verify --deep --strict`.
- The scripts in this fork were exercised with a full native rebuild and a disposable simulator installation; overwrite/whitespace refusal and cleanup after a deliberately failed build passed.

Companion/BLE communication is **not validated**. The Todo List sample's Add action still did nothing in the tested session, even after the companion runtime loaded. Firmware boot and deployment do not establish that every simulator feature works.

No physical-watch validation was performed. These results do not establish compatibility with every Zepp OS 6 API, full-screen layout, or asset qualifier. Other simulator versions, Intel hosts, Linux and Windows were not tested by this fork.

## Cleanup

Build objects are temporary and deleted automatically. Once installation succeeds, the output binary is redundant if you do not need another installation:

```sh
rm -- build-output/qemu-system-arm
rmdir build-output
```

Keep the checkout if you want to rebuild. The scripts never delete emulator source or the original simulator. Failed installations remove only the new copy created by that invocation. Existing destinations are always rejected.

## Attribution and license

QEMU is developed by the [QEMU project](https://www.qemu.org/); Zepp's simulator customizations come from [zepp-health/qemu](https://github.com/zepp-health/qemu). This fork is an independent community aid and is not an official Zepp release.

The QEMU emulator as a whole is GPL-2.0; individual components and bundled upstream firmware have their own notices. See [qemu/LICENSE](qemu/LICENSE), [qemu/COPYING](qemu/COPYING), and per-file licenses. Those notices remain intact. The new scripts are GPL-2.0-only. Do not assume the open source emulator license licenses the separately downloaded Zepp application or device firmware.
