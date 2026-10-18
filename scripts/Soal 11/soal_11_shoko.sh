#!/bin/bash
# DNS Slave - Shoko (10.76.1.3)
# Jalankan: ./shoko_slave.sh
set -Eeuo pipefail

DOMAIN="jujutsu.k25.com"
CONF_LOCAL="/etc/bind/named.conf.local"
CONF_OPTIONS="/etc/bind/named.conf.options"
CACHE_DIR="/var/cache/bind"

if [ "$(id -u)" -ne 0 ]; then
    echo "Error: jalankan sebagai root atau gunakan sudo."
    exit 1
fi

echo "== 1. Setup BIND9 =="

if ! command -v named >/dev/null 2>&1; then
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y bind9 bind9-utils dnsutils
fi

if ! command -v dig >/dev/null 2>&1; then
    DEBIAN_FRONTEND=noninteractive apt-get install -y dnsutils
fi

echo "== 2. Backup konfigurasi lama =="

BACKUP_SUFFIX="$(date +%Y%m%d%H%M%S)"
for FILE in "$CONF_LOCAL" "$CONF_OPTIONS"; do
    if [ -f "$FILE" ]; then
        cp -a "$FILE" "${FILE}.bak.${BACKUP_SUFFIX}"
    fi
done

echo "== 3. Konfigurasi zona Slave =="

cat > "$CONF_LOCAL" <<'EOF'
zone "jujutsu.k25.com" {
    type slave;
    masters { 10.76.1.2; };
    file "/var/cache/bind/db.jujutsu.k25.com";
};
EOF

cat > "$CONF_OPTIONS" <<'EOF'
options {
    directory "/var/cache/bind";
    recursion no;
    allow-query { any; };
    listen-on { any; };
    listen-on-v6 { any; };
};
EOF

mkdir -p "$CACHE_DIR"
chown bind:bind "$CACHE_DIR"
chmod 0755 "$CACHE_DIR"

echo "== 4. Validasi konfigurasi =="

named-checkconf

echo "== 5. Menjalankan atau memuat ulang BIND9 =="

if pgrep -x named >/dev/null 2>&1; then
    PID="$(pgrep -xo named)"
    kill -HUP "$PID"
    echo "Reload dikirim ke proses named (PID $PID)."
else
    named -u bind
fi

echo "== 6. Menunggu transfer zona dari Utahime =="

# Beri kesempatan Master mengirimkan zona.
sleep 3

echo "== 7. Pengujian DNS Slave =="

dig @127.0.0.1 "$DOMAIN" SOA +time=3 +tries=1
dig @10.76.1.3 "sync-test.$DOMAIN" A +time=3 +tries=1

echo
echo "Selesai: konfigurasi DNS Slave Shoko telah diterapkan."
echo "Jika zona belum tersedia, pastikan Utahime aktif dan transfer zona diizinkan."
