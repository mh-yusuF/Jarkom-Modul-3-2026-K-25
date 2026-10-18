#!/bin/sh
set -eu

cat > /etc/nginx/sites-available/frontend-proxy <<'EOF'
server {
    listen 80;
    server_name panda.jujutsu.k25.com;

    location / {
        proxy_pass http://10.76.4.4;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}

server {
    listen 80;
    server_name maki.jujutsu.k25.com;

    location / {
        proxy_pass http://10.76.4.8;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
EOF

ln -sf /etc/nginx/sites-available/frontend-proxy \
    /etc/nginx/sites-enabled/frontend-proxy

nginx -t
nginx -s reload 2>/dev/null || nginx

echo "Gojo: Frontend Reverse Proxy aktif."