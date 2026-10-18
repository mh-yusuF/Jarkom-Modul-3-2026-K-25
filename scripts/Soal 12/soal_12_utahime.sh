#!/bin/bash
set -Eeuo pipefail
[ "$(id -u)" -eq 0 ] || { echo "Jalankan sebagai root."; exit 1; }

DOMAIN="jujutsu.k25.com"
ZONE="/etc/bind/db.jujutsu.k25.com"
REV="/etc/bind/db.10.76.1"
LOCAL="/etc/bind/named.conf.local"
OPTIONS="/etc/bind/named.conf.options"
STAMP="$(date +%Y%m%d%H%M%S)"

for f in "$LOCAL" "$OPTIONS" "$ZONE" "$REV"; do
    [ ! -f "$f" ] || cp -a "$f" "$f.bak.$STAMP"
done

cat > "$LOCAL" <<'EOF'
zone "jujutsu.k25.com" {
    type master;
    file "/etc/bind/db.jujutsu.k25.com";
    allow-transfer { 10.76.1.3; };
    also-notify { 10.76.1.3; };
};
zone "1.76.10.in-addr.arpa" {
    type master;
    file "/etc/bind/db.10.76.1";
    allow-transfer { 10.76.1.3; };
    also-notify { 10.76.1.3; };
};
EOF

cat > "$ZONE" <<'EOF'
$TTL 86400
@ IN SOA ns1.jujutsu.k25.com. admin.jujutsu.k25.com. (
    2026101504 3600 1800 604800 86400
)
@       IN NS      ns1.jujutsu.k25.com.
@       IN NS      ns2.jujutsu.k25.com.
@       IN A       10.76.1.4
www     IN CNAME   jujutsu.k25.com.
ns1     IN A       10.76.1.2
ns2     IN A       10.76.1.3
utahime IN A       10.76.1.2
shoko   IN A       10.76.1.3
gojo    IN A       10.76.1.4
sync-test IN A     10.76.1.99
EOF

cat > "$REV" <<'EOF'
$TTL 86400
@ IN SOA ns1.jujutsu.k25.com. admin.jujutsu.k25.com. (
    2026101504 3600 1800 604800 86400
)
@ IN NS ns1.jujutsu.k25.com.
@ IN NS ns2.jujutsu.k25.com.
2 IN PTR ns1.jujutsu.k25.com.
3 IN PTR ns2.jujutsu.k25.com.
4 IN PTR jujutsu.k25.com.
EOF

cat > "$OPTIONS" <<'EOF'
options {
    directory "/var/cache/bind";
    recursion yes;
    allow-query { any; };
    allow-recursion { 127.0.0.1; 10.76.1.0/24; 10.76.2.0/24; };
    allow-query-cache { 127.0.0.1; 10.76.1.0/24; 10.76.2.0/24; };
    forwarders { 192.168.122.1; };
    forward first;
    listen-on { any; };
    listen-on-v6 { any; };
};
EOF

echo "== Validasi =="
named-checkconf
named-checkzone "$DOMAIN" "$ZONE"
named-checkzone "1.76.10.in-addr.arpa" "$REV"

echo "== Reload BIND =="
if pgrep -x named >/dev/null 2>&1; then
    kill -HUP "$(pgrep -xo named)"
    sleep 2
else
    named -u bind
    sleep 2
fi

echo "== Tes DNS =="
dig @127.0.0.1 "$DOMAIN" A +time=3 +tries=1
dig @127.0.0.1 "www.$DOMAIN" CNAME +time=3 +tries=1
dig @127.0.0.1 -x 10.76.1.4 +time=3 +tries=1
dig @127.0.0.1 google.com A +time=5 +tries=1
