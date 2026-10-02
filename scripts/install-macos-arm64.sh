#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-only
set -euo pipefail

fail() { printf 'Error: %s\n' "$*" >&2; exit 1; }
[[ $(uname -s) == Darwin && $(uname -m) == arm64 ]] || fail "Run in a native ARM64 macOS shell."
root=$(cd "$(dirname "$0")/.." && pwd)
[[ $# -ge 1 && $# -le 3 ]] || fail "Usage: $0 vendor.app [qemu-binary] [destination.app]"
vendor=$1
binary=${2:-"$root/build-output/qemu-system-arm"}
destination=${3:-"$HOME/Applications/ZeppSimulatorNative.app"}
[[ -d "$vendor/Contents" ]] || fail "Not an application bundle: $vendor"
vendor=$(cd "$vendor" && pwd -P)
[[ -f "$binary" && -x "$binary" ]] || fail "Build QEMU first: $binary"
[[ ! -e "$destination" && ! -L "$destination" ]] || fail "Destination already exists: $destination"
[[ "$destination" == *.app ]] || fail "Destination must end with .app."
mkdir -p "$(dirname "$destination")"
destination_parent=$(cd "$(dirname "$destination")" && pwd -P)
destination="$destination_parent/$(basename "$destination")"
[[ ! "$destination" =~ [[:space:]] ]] || fail "The simulator destination path must contain no whitespace."
[[ ! -e "$destination" && ! -L "$destination" ]] || fail "Destination already exists: $destination"
[[ "$destination" != "$vendor/"* ]] || fail "Destination must be outside the vendor bundle."
relative_binary=Contents/Resources/firmware/qemu_mac/qemu-system-arm
[[ -f "$vendor/$relative_binary" ]] || fail "Unrecognized simulator layout: $vendor"
[[ ! -L "$vendor/$relative_binary" ]] || fail "Unexpected symlink at vendor QEMU path."
/usr/bin/lipo -verify_arch arm64 "$binary" || fail "QEMU must include ARM64."
# Reserve the destination before enabling cleanup; never delete a preexisting path.
mkdir "$destination"
complete=0
cleanup() { if [[ "$complete" != 1 ]]; then rm -rf -- "$destination"; fi; }
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
/usr/bin/ditto "$vendor" "$destination"
cp "$binary" "$destination/$relative_binary"
for attribute in com.apple.FinderInfo com.apple.ResourceFork; do
  if /usr/bin/xattr -p "$attribute" "$destination/$relative_binary" >/dev/null 2>&1; then
    /usr/bin/xattr -d "$attribute" "$destination/$relative_binary"
  fi
done
/usr/bin/codesign --force --deep --sign - --preserve-metadata=entitlements "$destination"
/usr/bin/codesign --verify --deep --strict "$destination"
complete=1
printf 'Installed: %s\nLaunch with: open "%s"\n' "$destination" "$destination"
