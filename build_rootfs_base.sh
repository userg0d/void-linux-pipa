#!/usr/bin/env bash

source ./env.sh

# Cleanup function for rootfs
cleanup_rootfs() {
    echo "Cleaning up..."
    umount -R rootfs_mountpoint 2>/dev/null || true
    echo "Cleanup complete"
}
trap cleanup_rootfs EXIT ERR

if [ ! -d $WORKDIR ]; then
	mkdir $WORKDIR
fi

if [ ! -d $OUTDIR ]; then
	mkdir $OUTDIR
fi

pushd $WORKDIR

if [ ! -f "rootfs.tar.xz" ]; then
    wget $ROOTFS_URI -O rootfs.tar.xz
fi

if [ ! -f "qemu-aarch64-static" ]; then
    wget $QEMU_URI -O qemu-aarch64-static
    chmod +x qemu-aarch64-static
fi

# Setup binfmt_misc for aarch64 emulation
setup_binfmt_aarch64

truncate -s 6G linux.img
mkfs.ext4 linux.img

if [ ! -d "rootfs_mountpoint" ]; then
	mkdir rootfs_mountpoint
fi

mount linux.img rootfs_mountpoint

tar xvf rootfs.tar.xz -C rootfs_mountpoint

install -m755 qemu-aarch64-static rootfs_mountpoint/

mount --bind /dev rootfs_mountpoint/dev
mount --bind /dev/pts rootfs_mountpoint/dev/pts
mount --bind /proc rootfs_mountpoint/proc
mount --bind /sys rootfs_mountpoint/sys

echo "xiaomi-pad-6" > rootfs_mountpoint/etc/hostname
uuid=$(blkid -s UUID -o value linux.img)
echo "UUID=$uuid / f2fs defaults,relatime,discard 0 0" >> rootfs_mountpoint/etc/fstab
echo "nameserver 1.1.1.1" > rootfs_mountpoint/etc/resolv.conf
echo "root=UUID=$uuid loglevel=7 console=tty0 earlycon=tty0 keep_bootcon fbcon=rotate:1 fbcon=font:VGA8x16 rw" > rootfs_mountpoint/etc/cmdline
echo "GSK_RENDERER=gl" >> rootfs_mountpoint/etc/environment

chroot rootfs_mountpoint useradd -m -g users -G wheel user

# HACK: chpasswd doesn't really work for some reason
chroot rootfs_mountpoint bash -c "passwd root << EOD
root
root
EOD"
chroot rootfs_mountpoint bash -c "passwd user << EOD
1
1
EOD"

echo "%wheel ALL=(ALL:ALL) ALL" > rootfs_mountpoint/etc/sudoers.d/wheel

chroot rootfs_mountpoint xbps-install -Syu xbps
chroot rootfs_mountpoint xbps-install -Syuv
chroot rootfs_mountpoint xbps-install -Sy NetworkManager chrony fake-hwclock nano gst-plugins-good1 gst-plugins-bad1 gst-plugins-ugly1 gstreamer1 mesa-freedreno-dri gstreamer-vaapi mesa-vulkan-freedreno vulkan-loader pulseaudio pipewire bluez libspa-bluetooth

# Install zzz CPU control hook
mkdir -p rootfs_mountpoint/etc/zzz.d
install -m755 ../config/zzz/99-cpu-control.sh \
    rootfs_mountpoint/etc/zzz.d/99-cpu-control.sh

# Install zram service
mkdir -p rootfs_mountpoint/etc/sv/zram
install -m755 ../config/zram/run \
    rootfs_mountpoint/etc/sv/zram/run

# Install setup-de script
install -m755 ../config/setup-de rootfs_mountpoint/usr/local/bin/setup-de

# Install KDE configs for later use by setup-de
mkdir -p rootfs_mountpoint/usr/share/pipa-configs/kde/sddm
cp ../config/kde/sddm/*.conf rootfs_mountpoint/usr/share/pipa-configs/kde/sddm/

# Install conditional welcome message
mkdir -p rootfs_mountpoint/etc/profile.d
install -m644 ../config/welcome-message.sh rootfs_mountpoint/etc/profile.d/welcome-message.sh

# Enable services
chroot rootfs_mountpoint /bin/bash -c "ln -sv /etc/sv/dbus /etc/runit/runsvdir/default"
chroot rootfs_mountpoint /bin/bash -c "ln -sv /etc/sv/NetworkManager /etc/runit/runsvdir/default"
chroot rootfs_mountpoint /bin/bash -c "ln -sv /etc/sv/chronyd /etc/runit/runsvdir/default"
chroot rootfs_mountpoint /bin/bash -c "ln -sv /etc/sv/fake-hwclock /etc/runit/runsvdir/default"
chroot rootfs_mountpoint /bin/bash -c "ln -sv /etc/sv/zram /etc/runit/runsvdir/default"
chroot rootfs_mountpoint /bin/bash -c "ln -sv /etc/sv/bluetoothd /etc/runit/runsvdir/default"
chroot rootfs_mountpoint /bin/bash -c "ln -sv /etc/sv/pipa-bt-quirk /etc/runit/runsvdir/default"
chroot rootfs_mountpoint /bin/bash -c "ln -sv /etc/sv/qbootctl /etc/runit/runsvdir/default"

mkdir rootfs_mountpoint/repo
mount --bind repo rootfs_mountpoint/repo
# Install hooks and dracut modules first so they are in place before kernel triggers run dracut
chroot rootfs_mountpoint xbps-install -y --repository /repo pipa-hooks pipa-dracut-modules
# Install remaining packages (kernel triggers will now find all dracut modules)
chroot rootfs_mountpoint xbps-install -y --repository /repo $PACKAGES
umount rootfs_mountpoint/repo
rm -rf rootfs_mountpoint/repo

cp rootfs_mountpoint/boot/boot-*.img ../$OUTDIR/boot.img

rm rootfs_mountpoint/qemu-aarch64-static
umount -R rootfs_mountpoint
img2simg linux.img ../$OUTDIR/void_base.img
chown -Rvh 1000:1000 ../$OUTDIR
popd
