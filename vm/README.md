# Duo OS — Virtual Machine testing

Duo OS for Mac is a second Mac-style OS: **macOS 27.3 modified — but still
macOS 27.3**. It is not a macOS replacement. It runs as a VM OS.

- **Testing:** VirtualBox (first test host).
- **Shipping (May 1, 2027):** anyone can run Duo OS on **any VM they want**,
  on any Mac running **macOS 27.3 or later**. Duo OS is not limited to the
  Mac mini or to one VM app.
- **Release date: May 1, 2027.** Not ready before that date — the work is
  paced for quality to that date.

## Test setup status (2026-11-19)

- VirtualBox **7.2.22** (Apple Silicon / ARM build) installed on the build
  Mac (M3 MacBook Air, macOS 27.3, build 26C5035r) and opened in
  **Expert Mode**.
- A first VM named **Duo OS** was started in the New Virtual Machine wizard.
- Open item: the wizard's guest-OS selection could not be changed through
  remote control (its dropdown menus do not respond to remote input), and
  the VirtualBox ARM wizard defaults to Windows 11 on ARM. The guest-OS
  type for the Duo OS test VM must be confirmed in the wizard by hand, or
  the VM must be created with the VBoxManage script below.

## Files

- `create-duo-os-vm.sh` — creates the **Duo OS** test VM with VBoxManage
  (name, memory, CPUs, disk, EFI). Run it on the Mac from Terminal, or as a
  script step inside the Duo OS Xcode build — the recorded Duo OS build
  method. It does not install an OS; it only defines the VM.
