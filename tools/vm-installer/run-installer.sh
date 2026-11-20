#!/bin/sh
# Duo OS — run the VM installer tool (Mac VM track).
# Downloads the latest supported macOS restore image and installs a
# stock macOS 27.3 guest, writing a UTM config.plist so the guest
# opens in UTM as "Duo OS". Long-running: download + install.
# In the Mac Xcode project this runs via the run-installer target
# (Makefile: run-vm-installer); the paths below match that project.
set -e
cd "$(dirname "$0")/../.."
BIN="build/vm-installer/duo-os-vm-installer"
OUT="$HOME/Library/Containers/com.utmapp.UTM/Data/Documents/Duo OS.utm"
# Always rebuild (a few seconds) so source fixes actually land —
# building only when the binary is missing shipped a stale binary once.
sh ./tools/build_vm_installer.sh
if [ -e "$OUT" ]; then
  echo "error: $OUT already exists - refusing to overwrite" >&2
  exit 1
fi
mkdir -p "$(dirname "$OUT")"
exec "$BIN" --download-latest --out "$OUT"
