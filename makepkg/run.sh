#!/bin/bash

set -e

cd $(dirname $0)

if test $(id -u) = 0
then
	apt-get update
	apt-get install -y curl file git libarchive-tools makepkg

	ln -s /bin/true /usr/local/bin/pacman

	USERID=60000
	GROUPID=60000
	USERNAME=build

	groupadd -g $GROUPID $USERNAME
	useradd -u $USERID -g $GROUPID -m $USERNAME

	chown -R $USERNAME:$USERNAME .
	chown -R $USERNAME:$USERNAME ../src
	chown -R $USERNAME:$USERNAME ../debs

	su -c ./$(basename $0) $USERNAME

	chown -R 0:0 ../src

	userdel -r $USERNAME

	rm /usr/local/bin/pacman

	exit 0
fi

for PACKAGE in */
do
	echo $PACKAGE
	cd $PACKAGE

	export SRCDEST=$(pwd)/../../src/$PACKAGE
	export PKGDEST=$(pwd)/../../debs

	mkdir -p $SRCDEST

	makepkg -c

	cd ..
done
