#!/bin/sh
set -eu

mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled

cat > /etc/nginx/sites-available/api-proxy <<'EOF'
upstream api_workers {
    server 10.76.4.5:80;
    server 10.76.4.6:80;
    server 10.76.4.7:80 backup;
}

server {
    listen 80;
    server_name api.jujutsu.k25.com;

    location / {
        proxy_pass http://api_workers;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
EOF

ln -sfn /etc/nginx/sites-available/api-proxy \
    /etc/nginx/sites-enabled/api-proxy

nginx -t
nginx -s reload 2>/dev/null || nginx

echo "Geto selesai dipulihkan."