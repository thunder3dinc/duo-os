# Duo OS — Virtual Machine testing

Duo OS for Mac is a second Mac-style OS: **macOS 27.3 modified — but still
macOS 27.3**. It is not a macOS replacement. It runs as a VM OS.

- **Testing:** **UTM** is the macOS-guest host (Alan's decision,
  2026-11-19). VirtualBox was tried first and cannot be used for the
  macOS guest: VirtualBox on Apple Silicon offers no Mac OS X guest type.
  See `utm-duo-os-setup.md`.
- **Shipping (May 1, 2027):** anyone can run Duo OS on **any VM they want**,
  on any Mac running **macOS 27.3 or later**. Duo OS is not limited to the
  Mac mini or to one VM app.
- **Release date: May 1, 2027.** Not ready before that date — the work is
  paced for quality to that date.

## Test setup status (2026-11-19)

- VirtualBox **7.2.22** (Apple Silicon / ARM build) was installed and
  opened on the build Mac, and a VM named **Duo OS** was started in its
  wizard — but its guest-OS list has **no Mac OS X option** (only
  Windows / Linux / BSD / Other), so VirtualBox cannot host the macOS
  guest. Alan switched the macOS guest to **UTM**.
- **UTM 5.0.9** is installed and running on the build Mac (M3 MacBook
  Air, macOS 27.3, build 26C5035r). Disk space was freed for the VM
  (~24.8 GB of installers/IPAs/old IPSWs moved to Trash at Alan's
  direction; the iPhone Duo IPSWs are kept).
- Next step: create the **Duo OS** macOS VM in UTM using
  `utm-duo-os-setup.md`. UTM's window is not exposed to remote control,
  so that creation step is done at the Mac.

## Files

- `utm-duo-os-setup.md` — the UTM macOS-guest setup for Duo OS (current
  path).
- `create-duo-os-vm.sh` — the earlier VirtualBox VBoxManage script, kept
  for reference; VirtualBox is no longer the macOS-guest host.
