#!/bin/sh
set -eux

/opt/config.pl

cp /etc/resolv.conf /etc/resolv.dnsmasq.conf
echo "nameserver 127.0.0.1" > /etc/resolv.conf

exec /usr/bin/supervisord -c /etc/supervisord.conf -n

