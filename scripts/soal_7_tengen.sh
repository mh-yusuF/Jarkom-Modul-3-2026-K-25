#!/bin/bash
ok()    { echo -e "\e[32m[BERHASIL]\e[0m $1"; }
gagal() { echo -e "\e[31m[GAGAL]\e[0m $1"; }

CONF=/etc/dhcp/dhcpd.conf
LEASES=/var/lib/dhcp/dhcpd.leases

declare -A NAMA=(
  ["02:42:02:5f:98:00"]=itadori   ["02:42:60:2c:6f:00"]=fushiguro
  ["02:42:1a:10:47:00"]=zenin     ["02:42:7a:72:88:00"]=okkotsu
  ["02:42:f1:b3:8b:00"]=ino       ["02:42:a1:41:a7:00"]=kusakabe
  ["02:42:53:8a:f7:00"]=miwa      ["02:42:af:be:32:00"]=kugisaki
)

# 1. Lease dinamis aktif dari dhcpd.leases -> "ip mac"
AKTIF=$(awk '
  /^lease /{ip=$2}
  /^  binding state/{st=$3}
  /hardware ethernet/{mac=$3}
  /^}/{s[ip]=st; m[ip]=mac; st=""; mac=""}
  END{for(i in s) if(s[i]=="active;") print i, m[i]}
' $LEASES | tr -d ';')

# 2. Reservasi kugisaki dari dhcpd.conf (tidak dicatat di dhcpd.leases)
FIXIP=$(awk '/host kugisaki/{f=1} f&&/fixed-address/{gsub(";","",$2); print $2; exit}' $CONF)
FIXMAC=$(awk '/host kugisaki/{f=1} f&&/hardware ethernet/{gsub(";","",$3); print $3; exit}' $CONF)

ALL="$AKTIF"
if [ -n "$FIXIP" ] && ! echo "$AKTIF" | grep -q "$FIXMAC"; then
  ALL=$(printf "%s\n%s %s" "$AKTIF" "$FIXIP" "$FIXMAC")
fi
ALL=$(echo "$ALL" | sed '/^$/d' | sort -V)

echo "=== LEASE DINAMIS (dhcpd.leases) + RESERVASI (dhcpd.conf) ==="
printf "%-15s %-19s %-10s %s\n" IP MAC CLIENT SUMBER

while read -r IP MAC; do
  [ -z "$IP" ] && continue
  N=${NAMA[$MAC]:-tidak-dikenal}
  NET=$(echo $IP | cut -d. -f3); LAST=$(echo $IP | cut -d. -f4)
  case $N in
    itadori|fushiguro) EXN=2; MIN=10;  MAX=35  ;;
    zenin|okkotsu)     EXN=2; MIN=70;  MAX=95  ;;
    ino|kusakabe)      EXN=3; MIN=10;  MAX=89  ;;
    miwa)              EXN=3; MIN=100; MAX=199 ;;
    kugisaki)          EXN=3; MIN=99;  MAX=99  ;;
    *)                 EXN=0; MIN=0;   MAX=0   ;;
  esac
  SUMBER="leases"
  echo "$AKTIF" | grep -q "^$IP " || SUMBER="static (dhcpd.conf)"
  printf "%-15s %-19s %-10s %s\n" "$IP" "$MAC" "$N" "$SUMBER"
  if [ "$NET" = "$EXN" ] && [ "$LAST" -ge "$MIN" ] && [ "$LAST" -le "$MAX" ]; then
    ok "$N -> $IP sesuai kebijakan"
  else
    gagal "$N -> $IP di luar kebijakan pool"
  fi
done <<< "$ALL"

echo
echo "=== PEMERIKSAAN BENTROK ==="
[ -z "$(echo "$ALL" | awk '{print $1}' | sort | uniq -d)" ] && ok "tidak ada IP bertabrakan" || gagal "ada IP bertabrakan"
[ -z "$(echo "$ALL" | awk '{print $2}' | sort | uniq -d)" ] && ok "tidak ada MAC dengan lebih dari satu IP" || gagal "ada MAC dengan IP ganda"
echo "$ALL" | awk '{split($1,a,"."); if(a[3]==2 && a[4]>=36 && a[4]<=69) bad=1} END{exit bad}' \
  && ok "tidak ada IP di rentang terlarang 10.76.2.36-69" || gagal "ada IP di rentang 10.76.2.36-69"

echo
echo "=== KUGISAKI (fixed address) ==="
grep -A3 "host kugisaki" $CONF
[ "$FIXIP" = "10.76.3.99" ] && ok "reservasi kugisaki = 10.76.3.99" || gagal "reservasi kugisaki salah ($FIXIP)"
awk '/range/{gsub(";","");split($2,a,".");split($3,b,"."); if(10.76==10.76 && 99>=a[4] && 99<=b[4]) bad=1} END{exit bad}' $CONF \
  && ok "10.76.3.99 di luar seluruh range pool dinamis" || gagal "10.76.3.99 masuk range pool dinamis"
grep -q "10.76.3.99" $LEASES \
  || echo "[INFO] kugisaki tidak ada di dhcpd.leases: normal, host dengan fixed-address tidak dicatat di file itu"
ping -c 2 -W 2 10.76.3.99 > /dev/null && ok "kugisaki 10.76.3.99 reachable" || gagal "kugisaki 10.76.3.99 tidak reachable"