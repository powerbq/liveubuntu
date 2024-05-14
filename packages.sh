#!/bin/bash

set -e

echo 'Binary::apt::APT::Keep-Downloaded-Packages "1";' > /etc/apt/apt.conf.d/10apt-keep-downloads

echo "deb http://mirrors.kernel.org/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") main restricted universe multiverse" > /etc/apt/sources.list
echo "deb http://mirrors.kernel.org/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME")-security main restricted universe multiverse" >> /etc/apt/sources.list
echo "deb http://mirrors.kernel.org/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME")-updates main restricted universe multiverse" >> /etc/apt/sources.list

dpkg --add-architecture i386

apt-get update
apt-get upgrade -y
apt-get dist-upgrade -y

apt-get install -y gpg wget

if test "${SETUP_MOZILLA_SOURCE}" = y
then
	wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- > /etc/apt/keyrings/packages.mozilla.org.asc
	echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" > /etc/apt/sources.list.d/mozilla.list
	cat > /etc/apt/preferences.d/mozilla <<EOF
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
EOF
fi

if test "${SETUP_DOCKER_SOURCE}" = y
then
	wget -q https://download.docker.com/linux/ubuntu/gpg -O- > /etc/apt/keyrings/docker.asc
	echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list
fi

if test "${SETUP_SUBLIME_SOURCE}" = y
then
	wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | gpg --dearmor | tee /etc/apt/trusted.gpg.d/sublimehq-archive.gpg > /dev/null
	echo "deb https://download.sublimetext.com/ apt/stable/" | tee /etc/apt/sources.list.d/sublime-text.list
fi

apt-get update

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

for SCRIPT in $(find packages.sh.d -maxdepth 1 -type f -name '*.sh' | sort)
do
	$SCRIPT
done

apt-get install -y $(check-language-support -l ru)

if test -f /usr/libexec/docker/cli-plugins/docker-compose
then
	update-alternatives --install /usr/bin/docker-compose docker-compose /usr/libexec/docker/cli-plugins/docker-compose 1
fi

apt-get install -y zsh
./oh-my-zsh.sh

apt-get update
apt-get upgrade -y
apt-get dist-upgrade -y

apt-mark -y minimize-manual
update-initramfs -u
