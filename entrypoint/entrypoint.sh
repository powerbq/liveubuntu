#!/bin/bash

set -e

cd $(dirname $0)


# packages

echo 'Binary::apt::APT::Keep-Downloaded-Packages "1";' > /etc/apt/apt.conf.d/10apt-keep-downloads

echo "deb http://mirrors.kernel.org/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") main restricted universe multiverse" > /etc/apt/sources.list
echo "deb http://mirrors.kernel.org/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME")-security main restricted universe multiverse" >> /etc/apt/sources.list
echo "deb http://mirrors.kernel.org/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME")-updates main restricted universe multiverse" >> /etc/apt/sources.list

dpkg --add-architecture i386

apt-get update
apt-get upgrade -y
apt-get dist-upgrade -y

depends=(
)

depends+=(
	linux-image-generic
	linux-headers-generic
)

depends+=(
	casper
)

depends+=(
	busybox
	sudo
)

depends+=(
	squashfs-tools
)

depends+=(
	${MAIN_PACKAGE}
)

apt-get install -y ${depends[*]}

for PKGBUILD in $(find . -maxdepth 1 -type f -name 'PKGBUILD-*' | sort)
do
	depends=(
	)

	source $PKGBUILD

	apt-get install -y ${depends[*]}
done

for PKG in $(find debs -maxdepth 1 -type f -name '*.deb' | sort)
do
	apt install -y $(pwd)/$PKG
done

apt-get install -y gpg software-properties-common wget

for SCRIPT in $(find packages.sh.d -maxdepth 1 -type f -name '*.sh' | sort)
do
	$SCRIPT
done

if which check-language-support > /dev/null
then
	apt-get install -y $(check-language-support -l ru)
fi

apt-get update
apt-get upgrade -y
apt-get dist-upgrade -y
apt-get autoremove -y

#apt-mark -y minimize-manual
update-initramfs -u


# save

cd out

FILENAME=live_latest.squashfs

rm -f $FILENAME

mksquashfs / $FILENAME -ef ../excludes.txt -wildcards -no-xattrs -no-progress -comp zstd
sha256sum $FILENAME > $FILENAME.sha256sum

cat /boot/vmlinuz > vmlinuz
cat /boot/initrd.img > initrd.img

cd ..
