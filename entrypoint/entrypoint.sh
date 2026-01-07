#!/bin/bash

set -e

cd $(dirname $0)

FLAGFILE=.already-run-before
LOGFILE=/var/log/live-build.log
DEBOOTSTRAPLOGFILE=/var/log/live-debootstrap.log

if test -f $FLAGFILE
then
	echo "This container was already run before. Remove it and create new. Exiting..."
	exit 1
fi

touch $FLAGFILE


(


# delete old build

rm -f out/*


# save debootstrap cache
cp --update=older debootstrap/* debootstrap.bak/


# install packages

dpkg --add-architecture i386

apt-get update
apt-get upgrade -y
apt-get dist-upgrade -y

depends=(
)

depends+=(
	linux-generic
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

makepkg/run.sh

find ./debs -maxdepth 1 -type f -name '*.deb' | sort | xargs -r apt install -y

find ./packages.sh.d -maxdepth 1 -type f -name '*.sh' | sort | xargs -r -n 1 bash

apt-get update
apt-get upgrade -y
apt-get dist-upgrade -y
apt-get autoremove -y

update-initramfs -u


# save images

cd out

FILENAME=live_latest.squashfs

rm -f $FILENAME

mksquashfs / $FILENAME -ef ../excludes.txt -wildcards -no-xattrs -no-progress -comp zstd
sha256sum $FILENAME > $FILENAME.sha256sum

cat /boot/vmlinuz > vmlinuz
cat /boot/initrd.img > initrd.img

cd ..


# cleanup packages

cd debootstrap.bak

(
ls | sed 's/%3a/:/g' | awk -F _ '{print $1" "$2}'
cat $DEBOOTSTRAPLOGFILE | grep '^I: Validating ' | awk '{print $3" "$4}'
) | sort | uniq -u | xargs -r rm -Rfv

cd /var/cache/apt/archives

(
grep -oE 'Preparing to unpack \.\.\./[^ ]+'          $LOGFILE | cut -d '/' -f2 | sed -r 's/^[0-9]+-//' | sort -u
grep -oE 'Preparing to unpack \.\.\./archives/[^ ]+' $LOGFILE | cut -d '/' -f3 | sed -r 's/^[0-9]+-//' | sort -u
ls | sort -u
) | sort | uniq -u | xargs -r rm -Rfv


) 2>&1 | tee $LOGFILE


# save log

cat $DEBOOTSTRAPLOGFILE $LOGFILE > out/build.log
