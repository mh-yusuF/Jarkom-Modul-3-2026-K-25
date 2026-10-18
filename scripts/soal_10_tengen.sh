#!/bin/bash
exec > /root/autostart.log 2>&1
sleep 5
echo "nameserver 192.168.122.1" > /etc/resolv.conf

if ! which dhcpd > /dev/null; then
  for i in $(seq 1 60); do ping -c1 -W2 8.8.8.8 > /dev/null && break; sleep 3; done
  apt update && DEBIAN_FRONTEND=noninteractive apt install -y isc-dhcp-server
fi

grep -q 'class "pool1"' /etc/dhcp/dhcpd.conf || cp /root/dhcpd.conf.bak /etc/dhcp/dhcpd.conf
sed -i 's/^INTERFACESv4=.*/INTERFACESv4="eth0"/' /etc/default/isc-dhcp-server
touch /var/lib/dhcp/dhcpd.leases

dhcpd -t -cf /etc/dhcp/dhcpd.conf
service isc-dhcp-server restart
sleep 1
pgrep dhcpd > /dev/null || dhcpd -4 -q -cf /etc/dhcp/dhcpd.conf -lf /var/lib/dhcp/dhcpd.leases eth0
pgrep -a dhcpd && echo "[BERHASIL] dhcpd running"