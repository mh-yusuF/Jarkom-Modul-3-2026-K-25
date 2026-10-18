#!/bin/bash
ok()    { echo -e "\e[32m[BERHASIL]\e[0m $1"; }
gagal() { echo -e "\e[31m[GAGAL]\e[0m $1"; }

MAC_ITADORI="02:42:02:5f:98:00"
MAC_FUSHIGURO="02:42:60:2c:6f:00"
MAC_ZENIN="02:42:1a:10:47:00"
MAC_OKKOTSU="02:42:7a:72:88:00"

cat > /etc/dhcp/dhcpd.conf << EOF && ok "tulis dhcpd.conf" || gagal "tulis dhcpd.conf"
authoritative;
default-lease-time 600;
max-lease-time 7200;

class "pool1" {
  match if substring(hardware, 1, 6) = $MAC_ITADORI or substring(hardware, 1, 6) = $MAC_FUSHIGURO;
}

class "pool2" {
  match if substring(hardware, 1, 6) = $MAC_ZENIN or substring(hardware, 1, 6) = $MAC_OKKOTSU;
}

subnet 10.76.4.0 netmask 255.255.255.0 {
}

subnet 10.76.2.0 netmask 255.255.255.0 {
  option routers 10.76.2.1;
  option broadcast-address 10.76.2.255;

  pool {
    allow members of "pool1";
    range 10.76.2.10 10.76.2.35;
  }

  pool {
    allow members of "pool2";
    range 10.76.2.70 10.76.2.95;
  }
}

subnet 10.76.3.0 netmask 255.255.255.0 {
  range 10.76.3.10 10.76.3.89;
  option routers 10.76.3.1;
  option broadcast-address 10.76.3.255;
}
EOF

dhcpd -t -cf /etc/dhcp/dhcpd.conf && ok "validasi konfigurasi dhcpd" || gagal "validasi konfigurasi dhcpd"

service isc-dhcp-server restart && ok "restart service" || gagal "restart service"

sleep 1
pgrep dhcpd > /dev/null && ok "dhcpd running" || gagal "dhcpd tidak running"