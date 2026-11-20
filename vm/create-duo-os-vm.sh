#!/bin/bash
# Duo OS — create the VirtualBox test VM (defines the VM only; installs nothing).
# Duo OS is macOS 27.3 modified, but still macOS 27.3. It runs as a VM OS.
# Testing host: VirtualBox. Shipping (2027-05-01): any VM, any Mac on macOS 27.3+.
set -euo pipefail

VM_NAME="Duo OS"
VM_FOLDER="${HOME}/VirtualBox VMs"
# Test size for the M3 MacBook Air build machine. Scale up on the Mac mini.
VM_RAM_MB=8192
VM_CPUS=4
VM_DISK_MB=102400

VBOXMANAGE="/Applications/VirtualBox.app/Contents/MacOS/VBoxManage"

if [ ! -x "$VBOXMANAGE" ]; then
  echo "VBoxManage not found at $VBOXMANAGE — install VirtualBox first." >&2
  exit 1
fi

if "$VBOXMANAGE" list vms | grep -q "\"${VM_NAME}\""; then
  echo "A VM named '${VM_NAME}' already exists. Nothing changed."
  exit 0
fi

"$VBOXMANAGE" createvm --name "$VM_NAME" --basefolder "$VM_FOLDER" --register
"$VBOXMANAGE" modifyvm "$VM_NAME" --memory "$VM_RAM_MB" --cpus "$VM_CPUS" \
  --firmware efi --graphicscontroller vmsvga --accelerate-3d on
"$VBOXMANAGE" createhd --filename "${VM_FOLDER}/${VM_NAME}/${VM_NAME}.vdi" \
  --size "$VM_DISK_MB" --format VDI
"$VBOXMANAGE" storagectl "$VM_NAME" --name "SATA" --add sata --controller IntelAhci
"$VBOXMANAGE" storageattach "$VM_NAME" --storagectl "SATA" --port 0 --device 0 \
  --type hdd --medium "${VM_FOLDER}/${VM_NAME}/${VM_NAME}.vdi"

echo "VM '${VM_NAME}' created in ${VM_FOLDER}/${VM_NAME}."
echo "Next step (manual): set the guest OS type in VirtualBox and attach the"
echo "macOS 27.3 / Duo OS install media. Duo OS ships 2027-05-01, not earlier."
