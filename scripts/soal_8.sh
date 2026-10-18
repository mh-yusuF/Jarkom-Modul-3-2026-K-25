#!/bin/bash
ok()    { echo -e "\e[32m[BERHASIL]\e[0m $1"; }
gagal() { echo -e "\e[31m[GAGAL]\e[0m $1"; }

echo "nameserver 192.168.122.1" > /etc/resolv.conf
which tcpdump > /dev/null || { apt update && apt install -y tcpdump; }
which tcpdump > /dev/null && ok "tcpdump siap" || { gagal "tcpdump tidak terinstall"; exit 1; }

rm -f /root/dhcp.pcap
tcpdump -ni eth0 -vv -w /root/dhcp.pcap port 67 or port 68 > /dev/null 2>&1 &
PID=$!
sleep 2

echo
echo ">>> Capture jalan. Sekarang di client (itadori) jalankan:"
echo "      pkill udhcpc; udhcpc -i eth0"
echo ">>> Setelah client dapat IP, balik ke sini lalu tekan ENTER."
read -r

kill -INT $PID
wait $PID 2>/dev/null
sleep 1

echo
echo "=== HASIL CAPTURE ==="
tcpdump -nr /root/dhcp.pcap -vv 2>/dev/null \
  | grep -E "IP .*\.(67|68) >|DHCP-Message|Option 53|Gateway-IP|Your-IP|Server-ID|Lease-Time|Client-Ethernet"

echo
tcpdump -nr /root/dhcp.pcap -vv 2>/dev/null | grep -qi "Discover" && ok "DHCPDISCOVER tertangkap" || gagal "DHCPDISCOVER tidak tertangkap"
tcpdump -nr /root/dhcp.pcap -vv 2>/dev/null | grep -qi "Offer"    && ok "DHCPOFFER tertangkap"    || gagal "DHCPOFFER tidak tertangkap"
tcpdump -nr /root/dhcp.pcap -vv 2>/dev/null | grep -qi "Request"  && ok "DHCPREQUEST tertangkap"  || gagal "DHCPREQUEST tidak tertangkap"
tcpdump -nr /root/dhcp.pcap -vv 2>/dev/null | grep -qi "ACK"      && ok "DHCPACK tertangkap"      || gagal "DHCPACK tidak tertangkap"