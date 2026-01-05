# T2 MacBook Firmware Setup

This document covers the firmware setup required for Wi-Fi and Bluetooth on T2 MacBooks running Linux.

## Overview

T2 MacBooks require proprietary Broadcom firmware for Wi-Fi and Bluetooth to function. The firmware must be extracted from macOS and placed in `/lib/firmware/brcm/`.

## Prerequisites

- Access to macOS (either dual-boot or recovery image)
- The `firmware.sh` script (included in this repo)

## Methods

### Method 1: From macOS Directly (Recommended if dual-booting)

Run the firmware script on macOS:
```bash
bash firmware.sh
```

Choose option 1 to copy firmware to the EFI partition, then boot into Linux and run:
```bash
sudo mkdir -p /tmp/apple-wifi-efi
sudo mount /dev/nvme0n1p1 /tmp/apple-wifi-efi
bash /tmp/apple-wifi-efi/firmware.sh
sudo umount /tmp/apple-wifi-efi
```

### Method 2: From Linux (Download Recovery Image)

Run the firmware script on Linux:
```bash
bash ~/firmware.sh
```

Choose option 3 to download a macOS Recovery Image and extract firmware automatically.

### Method 3: From Linux (Mount macOS Partition)

If you have macOS installed, the script can mount and extract directly:
```bash
bash ~/firmware.sh
```

Choose option 2.

## Post-Installation

After firmware is installed, reload the kernel modules:
```bash
sudo modprobe -r brcmfmac_wcc
sudo modprobe -r brcmfmac
sudo modprobe brcmfmac
sudo modprobe -r hci_bcm4377
sudo modprobe hci_bcm4377
```

## Verification

Check Wi-Fi:
```bash
ip link show wlan0
nmcli device status
```

Check Bluetooth:
```bash
bluetoothctl show
```

## Firmware Location

Firmware files are installed to `/lib/firmware/brcm/` with names like:
- `brcmfmac4377b3-pcie.apple,*.bin` (Wi-Fi)
- `brcmbt4377b3-apple,*.bin` (Bluetooth)

## Troubleshooting

### Wi-Fi not working after kernel update
Re-run the firmware script or manually reload modules.

### Bluetooth not pairing
Ensure `hci_bcm4377` module is loaded:
```bash
lsmod | grep hci_bcm4377
```

## Resources

- [T2 Linux Wiki](https://wiki.t2linux.org)
- [Firmware script source](https://wiki.t2linux.org/tools/firmware.sh)
