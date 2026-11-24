#!/bin/bash
# Guards that the live ISO kernel, its boot entries and the install config all
# agree on linux-cachyos. Static only: it does not prove a built ISO boots.

set -e

root=$(realpath "${BASH_SOURCE[0]%/*}/../..")
fail() { echo "not ok - $*" >&2; exit 1; }

grep -qE '^arch_packages=\(.*\blinux-cachyos\b' "$root/builder/build-iso.sh" ||
  fail "build-iso.sh does not add linux-cachyos to the live package list"
grep -qF "sed -i -E '/^(linux|cloud-init)\$/d'" "$root/builder/build-iso.sh" ||
  fail "build-iso.sh no longer strips the stock linux package"
echo "ok - live ISO ships linux-cachyos and drops stock linux"

for f in configs/grub/grub.cfg configs/grub/loopback.cfg configs/syslinux/archiso_sys-linux.cfg configs/syslinux/archiso_pxe-linux.cfg; do
  grep -q 'vmlinuz-linux-cachyos' "$root/$f" || fail "$f has no linux-cachyos kernel entry"
  grep -q 'initramfs-linux-cachyos.img' "$root/$f" || fail "$f has no linux-cachyos initramfs entry"
  if grep -E 'vmlinuz-linux( |$)|initramfs-linux\.img' "$root/$f" >/dev/null; then
    fail "$f references the stock linux kernel"
  fi
done
echo "ok - every boot entry loads the linux-cachyos kernel and initramfs"

grep -qF 'echo "linux-cachyos"' "$root/configs/airootfs/root/configurator" ||
  fail "configurator detect_kernel is not linux-cachyos"
grep -qF 'kernel_choice=${kernel_choice:-linux-cachyos}' "$root/configs/airootfs/root/write-install-config" ||
  fail "write-install-config default kernel is not linux-cachyos"
grep -qF '"kernels": [ "$kernel_choice" ]' "$root/configs/airootfs/root/write-install-config" ||
  fail "write-install-config does not write the chosen kernel"
echo "ok - installed system defaults to linux-cachyos"
