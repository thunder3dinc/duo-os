# Duo OS — Specification Summary

This is the public summary of the Duo OS specification. Duo OS is built exactly to this plan.

## Foundations

- Duo OS versions track Apple's releases: the current base is the **27.3** line (build 24C5037i). Version **27.3.0.1** is also a Duo OS version.
- Duo OS is made by **reverse engineering Apple's own implementations** — the update flow and catalogue, build and kernel pieces, Settings, windowing, Assistive Access, Safari, StandBy, Control Center — and building against that map, so it behaves as if made by Apple. Behaviour is checked side-by-side against stock; any difference is a bug.
- The build runs on a Mac as an **Xcode build run by Swift Build**, with external tools (IPSW, kernelcache, OTA) as steps inside the build.
- Delivery is an update that appears in **Settings → General → Software Update** (Duo OS) or an **installer app** (Duo OS+ on Mac).
- Upgrading is **never forced**: the user picks STAY or upgrade.

## Duo OS (iPad / iPhone Duo)

- Target device class: iPad on iPadOS 27+; iPhone 11 and later (full screen); iPhone SE 2 / SE 3 (home button).
- **Duo Split View** replaces iPad Split View: divider lockable at 50/50; Duo-only same-app split view with real App Store apps.
- Keeps **Stage Manager** and **Slide Over**, plus **Windowed Apps** as a separate mode.
- **Desktop mode = Assistive Access**: cable to a monitor/TV enters Assistive Access automatically with the user's keyboard and mouse; the setup persists between entries. Lightning devices get Assistive Access but no desktop mode.
- Main apps are chosen at first launch; more main apps arrive in 27.3.0.1. Main GPS at first launch: Google Maps or Apple Maps (Waze joins in 27.3.0.1).
- Side-button main AI: (1) Apple Classic Mode, (2) Siri, (3) your AI of choice.
- Main files app: Finder, Files, Dropbox or Google Drive — ships with Finder; Files is not preinstalled and installs when chosen.
- Apple App Store is the principal store; a third-party store can replace it.
- Light and dark mode; wallpapers: stock, your own, and the ones you already had.
- Adaptive Power on all devices. Safari: no tab limit, Private and non-Private.
- Always On Display and jailbreak-style tweaks; everything the iOS, iPadOS and old iPod OS jailbreaks have (the old iPod OS itself is not included).
- CarPlay and CarPlay Ultra compatible.
- Runs all Mac, iPad and iPhone apps as if made for all three; also APK-compatible.
- Apple Pencil on iPad Air M1: Pencil 2, Pencil USB-C, Pencil Pro.
- Devices appear in Xcode as iOS devices.

## Duo OS+ (Mac)

- For the Mac mini; a **modified version of macOS 27 or later** with the iPhone Duo design.
- **StandBy** replaces screensavers; a cursor flick exits StandBy to the unlock screen.
- **Control Center is a combination** of the macOS Control Center and the iOS 27 Control Center.
- The **iOS/iPadOS App Library** is in; the macOS App Library is discontinued. Launchpad returns.
- **Stage Manager** from macOS and iPadOS; Duo Split View on Mac.
- Finder yes; iOS/iPadOS Files app no.
- StandBy replaces screensavers. No Slide Over (iPad-only).
- Function keys of any keyboard work (Mac or Windows layout, wired or Bluetooth).
- Xcode for Mac is supported — on the Mac only.
- Migration Assistant compatible; erase-install gives a clean Duo OS-only setup.
- Anyone can customize Duo OS+ how they want. Light and dark mode.

## Duo OS CarPlayOS (future — not in development yet)

A house smarthome edition of Duo OS for a 13-inch M4 iPad Air: everything from Duo OS, for the home, not the car.
