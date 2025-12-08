#!/bin/sh

if ! test $(id -u) = 0
then
	sudo $0
	exit $?
fi

set -e

cd $(dirname $0)

cd pkg-system

(
grep -oE 'Preparing to unpack \.\.\./[^ ]+' ../out/build-ubuntu.log | cut -d '/' -f2 | sed -r 's/^[0-9]+-//' | sort -u
ls | sort -u
) | sort | uniq -u | xargs -r rm -Rfv
