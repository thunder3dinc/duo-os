# Duo OS — build roadmap

**Release: May 1, 2027. Not earlier.** (Alan, 2026-11-19.) The pace is
deliberate: quality over rushing, one verified step at a time.

## The two tracks

### Track A — Duo OS for Mac (VM OS) — no bypass needed

Duo OS for Mac is **macOS 27.3 modified, but still macOS 27.3**, running
as a guest in a virtual machine (UTM / Apple Virtualization on the test
Mac; any VM on any Mac running macOS 27.3 or later once it ships).
Installing a macOS guest in a VM is a normal, supported thing to do —
nothing has to be bypassed, jailbroken, or tricked for this track.

Milestones:

1. **Guest exists** — create the **Duo OS** macOS VM in UTM
   (`vm/utm-duo-os-setup.md`). By-hand step at the Mac; UTM's window is
   not exposed to remote control.
2. **Base verified** — the guest boots stock macOS 27.3; record its
   build number and confirm it matches the 27.3 base.
3. **Duo OS layer, piece by piece** (each one checked side-by-side
   against stock behaviour, the recorded Duo OS method):
   - StandBy replaces screensavers; flick the cursor to dismiss it and
     unlock.
   - Control Center combining the macOS and iOS 27 Control Centers.
   - iOS/iPadOS App Library in place of the macOS App Library;
     Launchpad back.
   - Duo Split View + Stage Manager (macOS and iPadOS behaviours).
   - Finder stays; no iOS/iPadOS Files app.
4. **Package** — the finished guest ships as a VM image/bundle anyone
   can run in the VM of their choice.

### Track B — Duo OS for iPad / iPhone Duo (separate, unchanged)

The iPad/iPhone version is delivered as a Software Update on real
hardware. That track keeps its own standing state and is **not** part of
the VM work above; nothing in Track A depends on it, and the VM track
does not change it.

## Standing rules

- No comparison to older versions of Duo OS.
- Build exactly to the recorded spec (`docs/SPEC.md`); no drift.
- Licence: not picked yet — Alan's call, before any public release push.
