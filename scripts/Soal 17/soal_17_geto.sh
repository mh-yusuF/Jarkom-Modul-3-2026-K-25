#!/bin/bash
set -e

CONF="/etc/nginx/sites-available/api-proxy"
cp "$CONF" "$CONF.bak-no17"

cat > "$CONF" <<'NGINX'
upstream api_cluster {
    server 10.76.4.5:80 weight=3;
    server 10.76.4.6:80 weight=1;
}

server {
    listen 80;
    server_name api.jujutsu.k25.com;

    set_real_ip_from 10.76.1.4;
    real_ip_header X-Forwarded-For;
    real_ip_recursive on;

    location / {
        proxy_pass http://api_cluster;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $remote_addr;
    }
}
NGINX

nginx -t
nginx -s reload
echo "Geto: konfigurasi proxy tepercaya berhasil diterapkan."
