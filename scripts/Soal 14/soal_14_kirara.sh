#!/bin/sh
set -eu

cat > /etc/nftables.conf <<'EOF'
table inet worker_filter {
    chain input {
        type filter hook input priority 0; policy accept;
        ct state established,related accept
        iifname "lo" accept
        ip saddr 10.76.4.2 tcp dport 80 accept
        tcp dport 80 drop
    }
}
EOF

cat > /root/init.sh <<'EOF'
#!/bin/sh
nft delete table inet worker_filter 2>/dev/null || true
nft -f /etc/nftables.conf
EOF

chmod +x /root/init.sh
nft delete table inet worker_filter 2>/dev/null || true
nft -f /etc/nftables.conf

php-fpm8.4 -D 2>/dev/null || true
nginx -t
nginx -s reload 2>/dev/null || nginx

echo "Kirara selesai dipulihkan."
nft list table inet worker_filter