#!/bin/bash
ok()    { echo -e "\e[32m[BERHASIL]\e[0m $1"; }
gagal() { echo -e "\e[31m[GAGAL]\e[0m $1"; }

apt update && apt install -y isc-dhcp-server && ok "install isc-dhcp-server" || gagal "install isc-dhcp-server"

sed -i 's/^INTERFACESv4=.*/INTERFACESv4="eth0"/' /etc/default/isc-dhcp-server && ok "set interface eth0" || gagal "set interface eth0"

cat > /etc/dhcp/dhcpd.conf << 'EOF' && ok "tulis dhcpd.conf" || gagal "tulis dhcpd.conf"
authoritative;
default-lease-time 600;
max-lease-time 7200;

subnet 10.76.4.0 netmask 255.255.255.0 {
}

subnet 10.76.2.0 netmask 255.255.255.0 {
  range 10.76.2.10 10.76.2.35;
  option routers 10.76.2.1;
  option broadcast-address 10.76.2.255;
}

subnet 10.76.3.0 netmask 255.255.255.0 {
  range 10.76.3.10 10.76.3.89;
  option routers 10.76.3.1;
  option broadcast-address 10.76.3.255;
}
EOF

touch /var/lib/dhcp/dhcpd.leases

dhcpd -t -cf /etc/dhcp/dhcpd.conf && ok "validasi konfigurasi dhcpd" || gagal "validasi konfigurasi dhcpd"

service isc-dhcp-server restart && ok "restart service" || gagal "restart service"

sleep 1
pgrep dhcpd > /dev/null && ok "dhcpd running" || gagal "dhcpd tidak running"
ss -ulnp | grep -q ':67' && ok "dhcpd listen port 67" || gagal "dhcpd tidak listen port 67"