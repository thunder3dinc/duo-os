# Duo OS — UTM setup (macOS guest)

Alan's decision (2026-11-19): the macOS guest runs in **UTM**, not
VirtualBox. VirtualBox 7.2.22 on Apple Silicon has no Mac OS X guest type
at all (verified on the build Mac: its guest-OS list is only Windows /
Linux / BSD / Other), so VirtualBox cannot think it is installing macOS.
UTM uses Apple's Virtualization framework and can run a real macOS guest
on Apple Silicon.

- UTM version on the build Mac: **5.0.9** (verified in
  `/Applications/UTM.app`), the current release, with Apple Virtualization
  features for macOS 27 hosts.
- Duo OS is **macOS 27.3 modified — but still macOS 27.3**. In UTM the VM
  is a macOS VM; the Duo OS changes go on top of that guest.
- VM name: **Duo OS**.

## Create the VM (in UTM, on the Mac)

1. Open UTM → **Create a New Virtual Machine**.
2. Choose **Virtualize** (not Emulate).
3. Choose **macOS**.
4. IPSW: let UTM download the macOS restore image from Apple, or point it
   at a macOS 27.3 IPSW. This is a large download (~15 GB) — disk space
   was freed for this on 2026-11-19.
5. Hardware (build Mac, M3 MacBook Air): 4 CPU cores, 8192 MB memory.
   On the Mac mini (24 GB) these can be raised later.
6. Storage: 64 GB.
7. Name the VM **Duo OS** and finish. The first boot runs the macOS
   installer inside the VM — that installed macOS 27.3 is the base Duo OS
   is built on.

## Status

- 2026-11-19: UTM 5.0.9 installed and running on the build Mac. The VM
  creation clicks above have to be done at the Mac: UTM's window is not
  exposed to remote control (verified repeatedly), so this step is a
  by-hand step, then Duo OS work continues on the guest.
- Release pacing: Duo OS ships **May 1, 2027** — not earlier. This setup
  is step one of that schedule, not a rush to finish.
