#!/bin/sh
set -eu

php-fpm8.4 -D 2>/dev/null || true

nft delete table inet worker_filter 2>/dev/null || true

cat > /etc/nftables.conf <<'EOF'
table inet worker_filter {
    chain input {
        type filter hook input priority 0; policy accept;
        ct state established,related accept
        iifname "lo" accept
        ip saddr 10.76.1.4 tcp dport 80 accept
        tcp dport 80 drop
    }
}
EOF

nft -f /etc/nftables.conf
nginx -t
nginx -s reload 2>/dev/null || nginx

echo "Inumaki/Maki: Frontend Worker aktif."