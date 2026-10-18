
#!/bin/sh
set -eu

NGINX_CONF="/etc/nginx/nginx.conf"
SITE_CONF="/etc/nginx/sites-available/jujutsu-routing"
CACHE_DIR="/var/cache/nginx/frontend"

# 1. Pastikan file konfigurasi tersedia
if [ ! -f "$NGINX_CONF" ] || [ ! -f "$SITE_CONF" ]; then
    echo "ERROR: File konfigurasi Nginx tidak ditemukan."
    exit 1
fi

# 2. Backup konfigurasi sebelum diubah
cp "$NGINX_CONF" "${NGINX_CONF}.bak-soal19"
cp "$SITE_CONF" "${SITE_CONF}.bak-soal19"

# 3. Tambahkan zona cache dan rate limit jika belum ada
if ! grep -q 'keys_zone=frontend_cache:10m' "$NGINX_CONF"; then
    sed -i '/^[[:space:]]*http[[:space:]]*{/a\
    proxy_cache_path /var/cache/nginx/frontend levels=1:2 keys_zone=frontend_cache:10m inactive=10m max_size=100m;\
' "$NGINX_CONF"
fi

if ! grep -q 'zone=api_limit:10m' "$NGINX_CONF"; then
    sed -i '/^[[:space:]]*http[[:space:]]*{/a\
    limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;\
' "$NGINX_CONF"
fi

# 4. Siapkan direktori cache
mkdir -p "$CACHE_DIR"

# 5. Tambahkan rate limiting ke kedua lokasi API jika belum ada
# Penempatan dilakukan sebelum penutup location masing-masing.
# Untuk menghindari modifikasi otomatis yang berisiko pada konfigurasi
# existing, periksa apakah aturan sudah tersedia.
if ! grep -q 'limit_req zone=api_limit burst=10 nodelay;' "$SITE_CONF"; then
    echo "Tambahkan aturan limit_req ke location = /api dan location ^~ /api/ secara manual."
    echo "Script berhenti agar tidak merusak struktur konfigurasi yang sudah ada."
    exit 1
fi

# 6. Pastikan aturan cache frontend tersedia
if ! grep -q 'proxy_cache frontend_cache;' "$SITE_CONF"; then
    echo "Tambahkan aturan proxy_cache ke location / secara manual."
    echo "Script berhenti agar tidak merusak struktur konfigurasi yang sudah ada."
    exit 1
fi

# 7. Validasi dan reload
nginx -t
nginx -s reload

echo "Selesai: konfigurasi cache dan rate limit telah diperiksa."
