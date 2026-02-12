#!/usr/bin/env bash
ROOTFS_URI="https://repo-fi.voidlinux.org/live/current/void-aarch64-ROOTFS-20250202.tar.xz"
QEMU_URI="https://github.com/multiarch/qemu-user-static/releases/download/v7.2.0-1/qemu-aarch64-static"
XBPS_URI="https://repo-fi.voidlinux.org/static/xbps-static-latest.x86_64-musl.tar.xz"
REPO="https://repo-fi.voidlinux.org/voidlinux/current/aarch64"
PACKAGES="pipa-metapkg pipa-bt-quirk qbootctl"
PACKAGES_BUILD="pipa-metapkg pipa-bt-quirk pipa-sensors qbootctl"
WORKDIR="workdir"
OUTDIR="out"

# Function to setup binfmt_misc for aarch64 emulation
setup_binfmt_aarch64() {
    # Setup binfmt_misc for aarch64 emulation
    if ! mountpoint -q /proc/sys/fs/binfmt_misc; then
        modprobe binfmt_misc
        mount binfmt_misc /proc/sys/fs/binfmt_misc -t binfmt_misc
    fi

    # Remove old registrations if they exist
    [ -f /proc/sys/fs/binfmt_misc/aarch64 ] && echo -1 > /proc/sys/fs/binfmt_misc/aarch64 2>/dev/null || true
    [ -f /proc/sys/fs/binfmt_misc/aarch64ld ] && echo -1 > /proc/sys/fs/binfmt_misc/aarch64ld 2>/dev/null || true

    # Register aarch64 binary formats
    echo ':aarch64:M::\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xb7:\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff:/qemu-aarch64-static:' | tee /proc/sys/fs/binfmt_misc/register
    echo ':aarch64ld:M::\x7fELF\x02\x01\x01\x03\x00\x00\x00\x00\x00\x00\x00\x00\x03\x00\xb7:\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff:/qemu-aarch64-static:' | tee /proc/sys/fs/binfmt_misc/register
}
