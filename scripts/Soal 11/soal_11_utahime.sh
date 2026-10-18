
#!/bin/bash
# DNS Master - Utahime (10.76.1.2)
# Jalankan: ./utahime_master.sh
set -Eeuo pipefail

DOMAIN="jujutsu.k25.com"
ZONE_FILE="/etc/bind/db.jujutsu.k25.com"
CONF_LOCAL="/etc/bind/named.conf.local"
CONF_OPTIONS="/etc/bind/named.conf.options"

if [ "$(id -u)" -ne 0 ]; then
    echo "Error: jalankan sebagai root atau gunakan sudo."
    exit 1
fi

echo "== 1. Setup BIND9 =="

if ! command -v named >/dev/null 2>&1; then
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y bind9 bind9-utils dnsutils
fi

# Pastikan utilitas pengujian tersedia
if ! command -v dig >/dev/null 2>&1; then
    DEBIAN_FRONTEND=noninteractive apt-get install -y dnsutils
fi

echo "== 2. Backup konfigurasi lama =="

BACKUP_SUFFIX="$(date +%Y%m%d%H%M%S)"
for FILE in "$CONF_LOCAL" "$CONF_OPTIONS" "$ZONE_FILE"; do
    if [ -f "$FILE" ]; then
        cp -a "$FILE" "${FILE}.bak.${BACKUP_SUFFIX}"
    fi
done

echo "== 3. Konfigurasi zona Master =="

cat > "$CONF_LOCAL" <<'EOF'
zone "jujutsu.k25.com" {
    type master;
    file "/etc/bind/db.jujutsu.k25.com";
    allow-transfer { 10.76.1.3; };
    also-notify { 10.76.1.3; };
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

cat > "$ZONE_FILE" <<'EOF'
$TTL 86400
@ IN SOA ns1.jujutsu.k25.com. admin.jujutsu.k25.com. (
    2026101502 ; Serial
    3600        ; Refresh
    1800        ; Retry
    604800      ; Expire
    86400       ; Negative Cache TTL
)

@         IN NS ns1.jujutsu.k25.com.
@         IN NS ns2.jujutsu.k25.com.

ns1       IN A  10.76.1.2
ns2       IN A  10.76.1.3
utahime   IN A  10.76.1.2
shoko     IN A  10.76.1.3
gojo      IN A  10.76.1.4
sync-test IN A  10.76.1.99
EOF

chown root:bind "$ZONE_FILE" 2>/dev/null || true
chmod 0644 "$ZONE_FILE"

echo "== 4. Validasi konfigurasi =="

named-checkconf
named-checkzone "$DOMAIN" "$ZONE_FILE"

echo "== 5. Menjalankan atau memuat ulang BIND9 =="

if pgrep -x named >/dev/null 2>&1; then
    PID="$(pgrep -xo named)"
    kill -HUP "$PID"
    echo "Reload dikirim ke proses named (PID $PID)."
else
    mkdir -p /var/cache/bind
    named -u bind
fi

echo "== 6. Pengujian DNS Master =="

sleep 2
dig @127.0.0.1 "$DOMAIN" SOA +time=3 +tries=1
dig @10.76.1.2 "sync-test.$DOMAIN" A +time=3 +tries=1

echo
echo "Selesai: konfigurasi DNS Master Utahime telah diterapkan."
