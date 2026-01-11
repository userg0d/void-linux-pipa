#!/usr/bin/env bash
ROOTFS_URI="https://repo-fi.voidlinux.org/live/current/void-aarch64-ROOTFS-20250202.tar.xz"
QEMU_URI="wget https://github.com/multiarch/qemu-user-static/releases/download/v7.2.0-1/qemu-aarch64-static"
XBPS_URI="https://repo-fi.voidlinux.org/static/xbps-static-latest.x86_64-musl.tar.xz"
REPO="https://repo-fi.voidlinux.org/voidlinux/current/aarch64"
PACKAGES="pipa-metapkg pipa-bt-quirk qbootctl"
PACKAGES_BUILD="pipa-metapkg pipa-bt-quirk pipa-sensors qbootctl"
WORKDIR="workdir"
OUTDIR="out"
