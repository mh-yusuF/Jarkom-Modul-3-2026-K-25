
#!/bin/bash
set -e

CONF="/etc/nginx/sites-available/jujutsu-routing"

grep -q 'proxy_set_header X-Real-IP \$remote_addr;' "$CONF" || {
    echo "Tambahkan X-Real-IP pada location /api dan /api/ di $CONF"
    exit 1
}

grep -q 'proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;' "$CONF" || {
    echo "Tambahkan X-Forwarded-For pada location /api dan /api/ di $CONF"
    exit 1
}

nginx -t
nginx -s reload
echo "Gojo: konfigurasi header diperiksa dan Nginx dimuat ulang."
