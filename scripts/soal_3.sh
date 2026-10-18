#!/bin/bash
ok()    { echo -e "\e[32m[BERHASIL]\e[0m $1"; }
gagal() { echo -e "\e[31m[GAGAL]\e[0m $1"; }
apt update
DEBIAN_FRONTEND=noninteractive apt install -y isc-dhcp-relay && ok "install isc-dhcp-relay" || gagal "install isc-dhcp-relay"

cat > /etc/default/isc-dhcp-relay << 'EOF' && ok "tulis config relay" || gagal "tulis config relay"
SERVERS="10.76.4.10"
INTERFACES="eth2 eth3 eth4"
OPTIONS=""
EOF

service isc-dhcp-relay restart && ok "restart relay" || gagal "restart relay"

sleep 1
pgrep dhcrelay > /dev/null && ok "dhcrelay running" || gagal "dhcrelay tidak running"