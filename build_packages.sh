#!/usr/bin/env bash
source ./env.sh
set -x
echo "PACKAGES_BUILD=$PACKAGES_BUILD"

if [ ! -d $WORKDIR ]; then
	mkdir $WORKDIR
fi

pushd $WORKDIR

if [ ! -d "xbps-static" ];then
	wget $XBPS_URI -O xbps-static.tar.xz
	mkdir xbps-static
	tar xvf xbps-static.tar.xz -C xbps-static
fi

set -x
echo "PACKAGES_BUILD=$PACKAGES_BUILD"


export PATH=$(realpath xbps-static/usr/bin):$PATH

if [ ! -d "void-packages" ]; then
	git clone https://github.com/void-linux/void-packages --depth=1

fi

if [ ! -d "custom_repo" ]; then
    git clone https://github.com/userg0d/custom_repo --depth=1
fi

cp -r ../packages/* void-packages/srcpkgs/
cp -r custom_repo/srcpkgs/* void-packages/srcpkgs/

set -x
echo "PACKAGES_BUILD=$PACKAGES_BUILD"

if [ ! -d "repo" ]; then
	mkdir repo
	cd void-packages
	XBPS_ALLOW_CHROOT_BREAKOUT=1 ./xbps-src binary-bootstrap
	for PACKAGE in $PACKAGES_BUILD; do
		XBPS_ALLOW_CHROOT_BREAKOUT=1 ./xbps-src -a aarch64 pkg $PACKAGE
	done
	cp -rv hostdir/binpkgs/* ../repo
	cd ..
fi

popd
