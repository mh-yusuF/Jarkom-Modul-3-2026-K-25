#!/bin/sh
ok()    { printf "\033[32m[BERHASIL]\033[0m %s\n" "$1"; }
gagal() { printf "\033[31m[GAGAL]\033[0m %s\n" "$1"; }

NAMA=$(hostname)
echo "=== $NAMA: lepas IP lama, lalu minta lease baru ==="
ip addr flush dev eth0

udhcpc -i eth0 -n -t 3 -T 2
echo

INFO=$(ip -4 addr show eth0 | awk '/inet /{print $2}')
IP=${INFO%/*}
GW=$(ip route | awk '/^default/{print $3}')

if [ -z "$IP" ]; then
  gagal "$NAMA TIDAK dapat lease (gejala: DISCOVER terkirim, tidak ada OFFER)"
  ip -br addr show eth0
  exit 0
fi

NET=$(echo $IP | cut -d. -f3)
LAST=$(echo $IP | cut -d. -f4)
case $NAMA in
  itadori|fushiguro) EXN=2; MIN=10;  MAX=35  ;;
  zenin|okkutsu|okkotsu) EXN=2; MIN=70; MAX=95 ;;
  ino|kusakabe)      EXN=3; MIN=10;  MAX=89  ;;
  miwa)              EXN=3; MIN=100; MAX=199 ;;
  kugisaki)          EXN=3; MIN=99;  MAX=99  ;;
esac

ip -br addr show eth0
ip route
[ "$NET" = "$EXN" ] && [ "$LAST" -ge "$MIN" ] && [ "$LAST" -le "$MAX" ] \
  && ok "dapat $IP dari pool yang benar" || gagal "$IP di luar pool"
[ "$GW" = "10.76.$EXN.1" ] && ok "gateway semula $GW" || gagal "gateway salah ($GW)"