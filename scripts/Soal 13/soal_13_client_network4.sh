#!/bin/sh

apk update
apk add mariadb-client

echo "=== Versi MariaDB Client ==="
mariadb --version

echo
echo "=== Tes koneksi ke Yaga ==="
mariadb -h 10.76.4.9 -u dbuser -p db_shibuya_K25