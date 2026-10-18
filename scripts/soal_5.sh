#!/bin/bash
ok()    { echo -e "\e[32m[BERHASIL]\e[0m $1"; }
gagal() { echo -e "\e[31m[GAGAL]\e[0m $1"; }

KELOMPOK="K25"   # GANTI sesuai nama kelompokmu

# Network 2
MAC_ITADORI="02:42:02:5f:98:00"
MAC_FUSHIGURO="02:42:60:2c:6f:00"
MAC_ZENIN="02:42:1a:10:47:00"
MAC_OKKOTSU="02:42:7a:72:88:00"

# Network 3
MAC_INO="02:42:f1:b3:8b:00"
MAC_KUSAKABE="02:42:a1:41:a7:00"
MAC_MIWA="02:42:53:8a:f7:00"

cat > /etc/dhcp/dhcpd.conf << EOF && ok "tulis dhcpd.conf" || gagal "tulis dhcpd.conf"
authoritative;
default-lease-time 600;
max-lease-time 7200;

option domain-name-servers 10.76.1.2, 10.76.1.3;
option domain-search "$KELOMPOK.com";

class "pool1" {
  match if substring(hardware, 1, 6) = $MAC_ITADORI or substring(hardware, 1, 6) = $MAC_FUSHIGURO;
}

class "pool2" {
  match if substring(hardware, 1, 6) = $MAC_ZENIN or substring(hardware, 1, 6) = $MAC_OKKOTSU;
}

class "short" {
  match if substring(hardware, 1, 6) = $MAC_INO or substring(hardware, 1, 6) = $MAC_KUSAKABE;
  default-lease-time 1800;
  max-lease-time 1800;
}

class "long" {
  match if substring(hardware, 1, 6) = $MAC_MIWA;
  default-lease-time 43200;
  max-lease-time 43200;
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
  option routers 10.76.3.1;
  option broadcast-address 10.76.3.255;

  pool {
    allow members of "short";
    range 10.76.3.10 10.76.3.89;
  }

  pool {
    allow members of "long";
    range 10.76.3.100 10.76.3.199;
  }
}
EOF

dhcpd -t -cf /etc/dhcp/dhcpd.conf && ok "validasi konfigurasi dhcpd" || gagal "validasi konfigurasi dhcpd"

service isc-dhcp-server restart && ok "restart service" || gagal "restart service"

sleep 1
pgrep dhcpd > /dev/null && ok "dhcpd running" || gagal "dhcpd tidak running"