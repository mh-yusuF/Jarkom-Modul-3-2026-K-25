#!/bin/bash
exec > /root/autostart.log 2>&1
sleep 5
for i in $(seq 1 30); do ip -4 addr show eth0 | grep -q "inet " && break; sleep 2; done
echo "nameserver 192.168.122.1" > /etc/resolv.conf
echo 1 > /proc/sys/net/ipv4/ip_forward

which iptables > /dev/null || { apt update && apt install -y iptables; }
iptables -t nat -F
iptables -F FORWARD
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
for i in 1 2 3 4; do
  iptables -A FORWARD -i eth$i -o eth0 -j ACCEPT
  iptables -A FORWARD -i eth0 -o eth$i -m state --state RELATED,ESTABLISHED -j ACCEPT
done

which dhcrelay > /dev/null || { apt update && DEBIAN_FRONTEND=noninteractive apt install -y isc-dhcp-relay; }
pkill dhcrelay
dhcrelay -i eth2 -i eth3 -i eth4 10.76.4.10
sleep 1
pgrep -a dhcrelay && echo "[BERHASIL] relay running"