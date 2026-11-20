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

- First cut of `main.swift` written 2026-11-19. It has **not** been
  compiled yet: the next step is wiring it into the Duo OS Xcode
  project on the build Mac (with the Virtualization entitlement) and
  running the build there.
- Paced to the May 1, 2027 release — this is groundwork, done
  carefully, not a rush job.
