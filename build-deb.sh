#!/bin/bash
#
# Copyright (c) 2015 Vincent LAMAR, openlabs@lamar.fr
#
# This file is licensed under the terms of the GNU General Public
# License version 3. This program is licensed "as is" without any
# warranty of any kind, whether express or implied.
#
# ${SRC} ${BOARD} ${BRANCH} ${RELEASE} ${BUILD_DESKTOP}

SRC_REP="$1"
BOARD="$2"
BRANCH="$3"
RELEASE="$4"
BUILD_DESKTOP="$5"

BUILD_ROOTFS_REP="${SRC_REP}/output/cache/rootfs"
BUILD_DEB_REP="${SRC_REP}/output/debs/clean"

# Load libraries
source $SRC/lib/dialog.sh				# Deb packaging function
source $SRC/lib/packaging.sh				# Deb packaging function

configure_tty_screen

#if [[ -z $BOARD ]]; then
#	choose_board
#fi

if [[ -z $RELEASE ]]; then
	choose_release
fi

# List of Debian suites.
UNSTABLE_CODENAME="sid"
TESTING_CODENAME="stretch"
STABLE_CODENAME="jessie"
STABLE_BACKPORTS_SUITE="$STABLE_CODENAME-backports"
DEBIAN_SUITES=($UNSTABLE_CODENAME $TESTING_CODENAME $STABLE_CODENAME $STABLE_BACKPORTS_SUITE "unstable" "testing" "stable")

# List of Ubuntu suites.
UBUNTU_SUITES=("precise" "trusty" "xenial")

if $(echo ${UBUNTU_SUITES[@]} | grep -q $RELEASE); then
	OS="ubuntu"
fi

if $(echo ${DEBIAN_SUITES[@]} | grep -q $RELEASE); then
	OS="debian"
fi

if [ "$RELEASE" == "" ]; then
    echo "RELEASE is not set"
    exit 1
fi

if [ "$ARCH" == "" ]; then
	ARCH="armhf"
fi

if [[ ! -d ${BUILD_ROOTFS_REP} ]];then
	mkdir -p ${BUILD_ROOTFS_REP}
fi

if [[ ! -d ${BUILD_DEB_REP}/${OS}/${RELEASE} ]];then
	mkdir -p ${BUILD_DEB_REP}/${OS}/${RELEASE}
fi

check_dep pbuilder qemu-user-static devscripts binfmt-support
check_rootfs ${OS} ${RELEASE} ${ARCH} ${BUILD_ROOTFS_REP}
build_packages ${OS} ${RELEASE} ${ARCH} ${BUILD_ROOTFS_REP} ${BUILD_DEB_REP}
