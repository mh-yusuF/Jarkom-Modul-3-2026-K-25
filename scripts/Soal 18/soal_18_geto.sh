
#!/bin/bash
set -e

CONF="/etc/nginx/sites-available/api-proxy"

cp "$CONF" "$CONF.bak-no18"

sed -i '/^upstream api_cluster {/,/^}/c\
upstream api_cluster {\
    server 10.76.4.5:80 weight=3 max_fails=2 fail_timeout=5s;\
    server 10.76.4.6:80 weight=1 max_fails=2 fail_timeout=5s;\
    server 10.76.4.7:80 backup;\
}' "$CONF"

nginx -t
nginx -s reload

echo "Konfigurasi failover Geto selesai."
