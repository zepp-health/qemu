#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-only
set -euo pipefail

fail() { printf 'Error: %s\n' "$*" >&2; exit 1; }
[[ $(uname -s) == Darwin && $(uname -m) == arm64 ]] || fail "Run in a native ARM64 macOS shell."
root=$(cd "$(dirname "$0")/.." && pwd)
output=${1:-"$root/build-output/qemu-system-arm"}
[[ $# -le 1 ]] || fail "Usage: $0 [output-binary]"
[[ ! -e "$output" && ! -L "$output" ]] || fail "Output already exists: $output"
python=${QEMU_PYTHON:-/usr/bin/python3}
[[ -x "$python" ]] || fail "Python not executable: $python (set QEMU_PYTHON)."
jobs=${JOBS:-6}
[[ "$jobs" =~ ^[1-9][0-9]*$ ]] || fail "JOBS must be a positive integer."
for tool in ninja pkg-config clang strip codesign brew; do
  command -v "$tool" >/dev/null || fail "Missing tool: $tool. See README prerequisites."
done
glib_prefix=$(brew --prefix glib)
pixman_prefix=$(brew --prefix pixman)
export PKG_CONFIG_PATH="$glib_prefix/lib/pkgconfig:$pixman_prefix/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
pkg-config --exists glib-2.0 pixman-1 || fail "glib/pixman development libraries not found."
mkdir -p "$(dirname "$output")"
output_dir=$(cd "$(dirname "$output")" && pwd)
output="$output_dir/$(basename "$output")"
build_dir=$(mktemp -d "${TMPDIR:-/tmp}/zepp-qemu-build.XXXXXX")
trap 'rm -rf -- "$build_dir"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
cd "$build_dir"
"$root/qemu/configure" --target-list=arm-softmmu --enable-cocoa \
  --enable-slirp=git --disable-hvf --disable-docs --disable-werror \
  --python="$python"
ninja -j "$jobs" qemu-system-arm
strip -S -x qemu-system-arm
codesign --force --sign - qemu-system-arm
[[ ! -e "$output" && ! -L "$output" ]] || fail "Output appeared during build: $output"
mv -n qemu-system-arm "$output"
[[ ! -e qemu-system-arm ]] || fail "Output appeared during installation: $output"
printf 'Built: %s\nTemporary build directory will be removed.\n' "$output"
