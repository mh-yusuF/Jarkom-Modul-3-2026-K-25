#!/bin/sh
ok()    { printf "\033[32m[BERHASIL]\033[0m %s\n" "$1"; }
gagal() { printf "\033[31m[GAGAL]\033[0m %s\n" "$1"; }

KELOMPOK="K25"

# Helper udhcpc supaya domain-search masuk ke resolv.conf
echo '#!/bin/sh' > /root/udhcpc.script
echo '/usr/share/udhcpc/default.script "$@"' >> /root/udhcpc.script
echo 'if [ "$1" = "bound" ] || [ "$1" = "renew" ]; then' >> /root/udhcpc.script
echo '  S="${search:-$domain}"' >> /root/udhcpc.script
echo '  if [ -n "$S" ]; then' >> /root/udhcpc.script
echo '    sed -i "/^search/d" /etc/resolv.conf' >> /root/udhcpc.script
echo '    echo "search $S" >> /etc/resolv.conf' >> /root/udhcpc.script
echo '  fi' >> /root/udhcpc.script
echo 'fi' >> /root/udhcpc.script
chmod +x /root/udhcpc.script

# Minta lease baru
pkill udhcpc
udhcpc -i eth0 -O search -s /root/udhcpc.script
sleep 1

NAMA=$(hostname)
INFO=$(ip -4 addr show eth0 | awk '/inet /{print $2}')
IP=${INFO%/*}
CIDR=${INFO#*/}
BRD=$(ip -4 addr show eth0 | awk '/inet /{for(i=1;i<=NF;i++) if($i=="brd") print $(i+1)}')
GW=$(ip route | awk '/^default/{print $3}')
NET=$(echo $IP | cut -d. -f3)
LAST=$(echo $IP | cut -d. -f4)

echo
echo "=== $NAMA | IP $IP/$CIDR | GW $GW | BRD $BRD ==="
ip route
cat /etc/resolv.conf
echo

case $NAMA in
  itadori|fushiguro) EXN=2; MIN=10;  MAX=35  ;;
  zenin|okkutsu)     EXN=2; MIN=70;  MAX=95  ;;
  ino|kusakabe)      EXN=3; MIN=10;  MAX=89  ;;
  miwa)              EXN=3; MIN=100; MAX=199 ;;
  kugisaki)          EXN=3; MIN=99;  MAX=99  ;;
  *)                 EXN=0; MIN=0;   MAX=0   ;;
esac

[ "$CIDR" = "24" ] && ok "subnet mask /24 (255.255.255.0)" || gagal "subnet mask bukan /24"
[ "$GW" = "10.76.$NET.1" ] && ok "gateway $GW" || gagal "gateway salah ($GW)"
[ "$BRD" = "10.76.$NET.255" ] && ok "broadcast $BRD" || gagal "broadcast salah ($BRD)"
grep -q "nameserver 10.76.1.2" /etc/resolv.conf && grep -q "nameserver 10.76.1.3" /etc/resolv.conf \
  && ok "DNS 10.76.1.2 dan 10.76.1.3" || gagal "DNS belum sesuai"
grep -E "^(search|domain)" /etc/resolv.conf | grep -q "$KELOMPOK.com" \
  && ok "domain-search $KELOMPOK.com" || gagal "domain-search belum muncul"
[ "$NET" = "$EXN" ] && [ "$LAST" -ge "$MIN" ] && [ "$LAST" -le "$MAX" ] \
  && ok "IP $IP sesuai pool ($EXN.$MIN-$MAX)" || gagal "IP $IP di luar kebijakan pool"
ping -c 2 -W 2 "$GW" > /dev/null && ok "ping gateway $GW" || gagal "ping gateway $GW"