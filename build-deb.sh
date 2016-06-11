#!/bin/bash
#
# Copyright (c) 2015 Vincent LAMAR, openlabs@lamar.fr
#
# This file is licensed under the terms of the GNU General Public
# License version 3. This program is licensed "as is" without any
# warranty of any kind, whether express or implied.
SRC_REP="$1"
ARCH="$2"
OS="$3"
DIST="$4"

BUILD_REP="${SRC_REP}/lib/bin/build"
BUILD_DEB_REP="${BUILD_REP}/sunxi-debs"
if [[ ! -d ${BUILD_DEB_REP} ]];then mkdir -p ${BUILD_DEB_REP};fi

if [ "$OS" == "debian" ]; then
    : ${DIST:="jessie"}
    : ${ARCH:="armhf"}
elif [ "$OS" == "ubuntu" ]; then
    : ${DIST:="trusty"}
    : ${ARCH:="armhf"}
else
    echo "Unknown OS: $OS"
#    exit 1
fi

if [ "$DIST" == "" ]; then
    echo "DIST is not set"
#    exit 1
fi

if [ "$ARCH" == "" ]; then
    echo "ARCH is not set"
#    exit 1
fi

check_dep ()
{
#------------------------------------------
# Get updates of the main build libraries #
#------------------------------------------
PACKAGES=$*

INTALL_PACKAGES=""
for p in ${PACKAGES};do
	if [[ $(dpkg-query -W -f='${db:Status-Abbrev}\n' ${p} 2>/dev/null) != *ii* ]];then
		INTALL_PACKAGES="${INTALL_PACKAGES} ${p}"
	fi
done
if [[ ! ${INTALL_PACKAGES} == "" ]]; then
	apt-get update
	apt-get -qq -y --no-install-recommends install ${INTALL_PACKAGES}
	if [[ ! "$( echo ${INTALL_PACKAGES} | grep pbuilder )" == "" ]];then 
		config_pbuilder
	fi
fi

}

config_pbuilder ()
{
#---------------------
# Configure pbuilder #
#---------------------

PROXY_URL=""

if [[ ! -d ${BUILD_DEB_REP} ]];then mkdir -p ${BUILD_DEB_REP};fi

cat <<EOF > /etc/pbuilderrc
#!/bin/bash
# this is your configuration file for pbuilder.
# the file in /usr/share/pbuilder/pbuilderrc is the default template.
# /etc/pbuilderrc is the one meant for overwriting defaults in
# the default template
#
# read pbuilderrc.5 document for notes on specific options.

set -e

export http_proxy="$PROXY_URL"

if [ "\$OS" == "debian" ]; then
    MIRRORSITE="http://ftp.debian.org/debian/"
    COMPONENTS="main contrib non-free"
    DEBOOTSTRAPOPTS=("\\\${DEBOOTSTRAPOPTS[@]}" "--keyring=/usr/share/keyrings/debian-archive-keyring.gpg")
    : \${DIST:="jessie"}
    : \${ARCH:="armhf"}
elif [ "\$OS" == "ubuntu" ]; then
    MIRRORSITE="http://ports.ubuntu.com/ubuntu-ports/"
    COMPONENTS="main universe multiverse"
    DEBOOTSTRAPOPTS=("\\\${DEBOOTSTRAPOPTS[@]}" "--keyring=/usr/share/keyrings/ubuntu-archive-keyring.gpg")
    : \${DIST:="trusty"}
    : \${ARCH:="armhf"}
else
    echo "Unknown OS: \${OS}"
    exit 1
fi

if [ "\${DIST}" == "" ]; then
    echo "DIST is not set"
    exit 1
fi

if [ "\${ARCH}" == "" ]; then
    echo "ARCH is not set"
    exit 1
fi

NAME="\$OS-\$DIST-\$ARCH"

if [[ ! "\$(dpkg-architecture -qDEB_BUILD_ARCH)" == "\$ARCH" ]]; then
    echo USE QEMU DEBOOTSTRAP
    DEBOOTSTRAP="qemu-debootstrap"
fi

DEBOOTSTRAPOPTS=("\\\${DEBOOTSTRAPOPTS[@]}" "--arch=\$ARCH")
BASETGZ="${BUILD_REP}/\$NAME-base.tgz"
DISTRIBUTION="\$DIST"
BUILDRESULT="${BUILD_DEB_REP}"
APTCACHE="/var/cache/pbuilder/\$NAME/aptcache/"
BUILDPLACE="/var/cache/pbuilder/build"
HOOKDIR="/var/cache/pbuilder/hook.d/"
EOF
sed -i 's/\\//' /etc/pbuilderrc
}

check_rootfs ()
{
#--------------------------
# Check and create rootfs #
#--------------------------

DISTRO="$1"
VERSION="$2"
TYPE="$3"
NAME="${OS}-${DIST}-${ARCH}"

if [[ ! -f ${BUILD_REP}/$NAME-base.tgz ]];then
	OS=${DISTRO} DIST=${VERSION} ARCH=${TYPE} pbuilder --create
fi
}

build_packages ()
{
DISTRO="$1"
VERSION="$2"
TYPE="$3"

PACKAGES=$(ls ${SRC_REP}/lib/config/deb | sed s'/.conf//')
for p in ${PACKAGES};do
	. ${SRC_REP}/lib/config/deb/${p}.conf
	case $Type in
		dsc)
			cd ..
			if [[ ! -d tmp ]];then mkdir tmp;fi
			if [[ -d tmp ]];then rm -r tmp/*;fi
			cd tmp
			dget -ux $Url
			cd ${Rep}
			echo "OS=${DISTRO} DIST=${VERSION} ARCH=${TYPE} pdebuild"
			read a
			OS=${DISTRO} DIST=${VERSION} ARCH=${TYPE} pdebuild --architecture armhf --logfile /tmp/pbdebuild.log
			;;
		git)
			echo "Git"
			;;

	esac
done
}

#-------------------------------------------------------------------------
# 	Main
#-------------------------------------------------------------------------

check_dep pbuilder qemu-user-static devscripts binfmt-support
check_rootfs ${OS} ${DIST} ${ARCH}
build_packages ${OS} ${DIST} ${ARCH}
