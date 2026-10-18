#!/bin/bash
ok()    { echo -e "\e[32m[BERHASIL]\e[0m $1"; }
gagal() { echo -e "\e[31m[GAGAL]\e[0m $1"; }

case "$1" in
  mati)
    pkill dhcrelay
    sleep 1
    pgrep dhcrelay > /dev/null && gagal "relay masih jalan" || ok "DHCP relay dimatikan"
    ;;
  nyala)
    pkill dhcrelay
    dhcrelay -i eth2 -i eth3 -i eth4 10.76.4.10
    sleep 1
    pgrep -a dhcrelay > /dev/null && ok "DHCP relay dinyalakan: $(pgrep -a dhcrelay)" || gagal "relay tidak jalan"
    ;;
  *)
    echo "Pakai: bash /root/soal_9.sh mati | nyala"
    ;;
esac