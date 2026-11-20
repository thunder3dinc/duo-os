# Duo OS VM installer tool

## Why this exists

UTM's window is not exposed to macOS Accessibility, so it cannot be
driven by remote control (verified repeatedly on the build Mac,
2026-11-19). The clicks to create the **Duo OS** macOS VM in UTM
therefore cannot be automated from outside UTM.

Xcode **can** be driven, and the recorded Duo OS build method is an
Xcode build with script steps. So the VM gets created the Duo OS way:
a small Swift tool, built and run as a step of the Duo OS Xcode build
on the Mac, that uses Apple's **Virtualization framework** — the same
framework UTM itself uses — to install a stock macOS 27.3 guest and
save it where UTM can open it.

No bypass is involved: installing a macOS guest in a VM is a normal,
supported operation.

## What the tool does

1. Takes the macOS 27.3 restore image (IPSW): a local path, or it
   downloads Apple's current macOS restore image for virtual machines.
2. Asks the restore image for its most featureful supported hardware
   configuration (hardware model + machine identifier), and creates
   the auxiliary storage — the pieces a Mac VM needs to exist.
3. Creates a blank disk image (64 GB, sparse).
4. Runs `VZMacOSInstaller` to install macOS onto the disk, reporting
   progress.
5. Saves everything as a VM bundle named **Duo OS**, in the folder
   UTM keeps its virtual machines in, so the finished guest appears
   in UTM's list, ready to boot and receive the Duo OS layer.

## Status

- 2026-11-19: first cut of `main.swift` written; wired into the Duo OS
  Xcode project on the build Mac as a second external-build target
  named **vm-installer** (Makefile target `vm-installer`, script
  `tools/build_vm_installer.sh`, Virtualization entitlement in
  `tools/vm-installer/vm-installer.entitlements`).
- The tool also writes a UTM `config.plist`, so the finished bundle is
  a `.utm` package UTM can open and boot.
- **Build Succeeded in Xcode on the build Mac, 2026-11-19 21:37 EST**
  (one compile error found and fixed on the way: the macOS 27 SDK's
  `VZMacOSInstaller` completion handler returns a `Result`, not an
  optional error). Binary verified on disk:
  `Downloads/duo os/build/vm-installer/duo-os-vm-installer`.
- Next step: run the tool to perform the actual guest install. That
  needs the freed disk space (Trash emptied on the Mac) for the
  ~15 GB restore-image download and the guest disk.
- Paced to the May 1, 2027 release — this is groundwork, done
  carefully, not a rush job.
