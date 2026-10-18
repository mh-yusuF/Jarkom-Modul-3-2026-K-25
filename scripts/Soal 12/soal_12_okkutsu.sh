#!/bin/bash
set -Eeuo pipefail
[ "$(id -u)" -eq 0 ] || { echo "Jalankan sebagai root."; exit 1; }

RESOLV="/etc/resolv.conf"
STAMP="$(date +%Y%m%d%H%M%S)"
[ ! -f "$RESOLV" ] || cp -a "$RESOLV" "$RESOLV.bak.$STAMP"

cat > "$RESOLV" <<'EOF'
nameserver 10.76.1.2
options timeout:2 attempts:2
EOF

echo "== Informasi jaringan =="
ip -4 addr show
ip route
echo "== A record =="
dig @10.76.1.2 jujutsu.k25.com A +time=3 +tries=1
echo "== CNAME =="
dig @10.76.1.2 www.jujutsu.k25.com CNAME +time=3 +tries=1
echo "== PTR =="
dig @10.76.1.2 -x 10.76.1.4 +time=3 +tries=1
echo "== DNS Forwarder =="
dig @10.76.1.2 google.com A +time=5 +tries=1
echo "== Ping internet =="
ping -c 3 -W 3 google.com
