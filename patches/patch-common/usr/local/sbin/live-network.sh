#!/bin/bash

ln -s /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

if test "${NETWORK_CUSTOM}" = yes
then
	rm /etc/netplan/01-network-manager-all.yaml
fi

exit 0
