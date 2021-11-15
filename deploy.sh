#!/bin/bash

set -eu

read -p "Enter the target device: " -r target_device
if [ ! -b "$target_device" ]; then
    echo "Bad target device \"${target_device}\"" >&2
    exit 1
fi

read -p "⚠️  Are you sure you want to overwrite $target_device (y/[n])? " -r answer
if [[ ! "$answer" =~ ^[yY]$ ]]; then
    exit
fi

# Install on the target device
sudo -k docker run --pull=always --privileged --rm \
    -v /dev:/dev -v /run/udev:/run/udev -v "$PWD":/data -w /data \
    quay.io/coreos/coreos-installer:release \
    install --architecture=aarch64 --ignition-file config.ign \
    "$target_device"

# Install UEFI firmware
efi_partition=$(\
    lsblk "$target_device" -J -oLABEL,PATH \
    | jq -r '(.blockdevices[] | select(.label == "EFI-SYSTEM")).path' \
)
tempdir=$(mktemp -d)
pushd "$tempdir"
mkdir mountpoint
curl -sSL https://api.github.com/repos/pftf/RPi4/releases/latest \
    | jq -r '(.assets[] | select(.name|test("RPi4_UEFI_Firmware_v.*zip"))).browser_download_url' \
    | xargs -n1 curl -L -o firmware.zip
sudo mount "$efi_partition" mountpoint
sudo unzip -d mountpoint firmware.zip
sudo umount "$efi_partition"
popd
rm -r "$tempdir"
