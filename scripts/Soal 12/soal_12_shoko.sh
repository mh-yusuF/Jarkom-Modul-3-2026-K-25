#!/bin/bash
set -Eeuo pipefail
[ "$(id -u)" -eq 0 ] || { echo "Jalankan sebagai root."; exit 1; }

LOCAL="/etc/bind/named.conf.local"
OPTIONS="/etc/bind/named.conf.options"
STAMP="$(date +%Y%m%d%H%M%S)"
for f in "$LOCAL" "$OPTIONS"; do
    [ ! -f "$f" ] || cp -a "$f" "$f.bak.$STAMP"
done

cat > "$LOCAL" <<'EOF'
zone "jujutsu.k25.com" {
    type slave;
    masters { 10.76.1.2; };
    file "/var/cache/bind/db.jujutsu.k25.com";
};
zone "1.76.10.in-addr.arpa" {
    type slave;
    masters { 10.76.1.2; };
    file "/var/cache/bind/db.10.76.1";
};
EOF

cat > "$OPTIONS" <<'EOF'
options {
    directory "/var/cache/bind";
    recursion no;
    allow-query { any; };
    listen-on { any; };
    listen-on-v6 { any; };
};
EOF

mkdir -p /var/cache/bind
chown bind:bind /var/cache/bind
named-checkconf
if pgrep -x named >/dev/null 2>&1; then
    kill -HUP "$(pgrep -xo named)"
    sleep 2
else
    named -u bind
    sleep 2
fi

echo "== Tes zona melalui Shoko =="
dig @127.0.0.1 jujutsu.k25.com A +time=3 +tries=1
dig @127.0.0.1 www.jujutsu.k25.com CNAME +time=3 +tries=1
dig @127.0.0.1 -x 10.76.1.4 +time=3 +tries=1
