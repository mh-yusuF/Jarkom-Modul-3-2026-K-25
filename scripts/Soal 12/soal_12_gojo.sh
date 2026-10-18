#!/bin/bash
set -Eeuo pipefail
EXPECTED_IP="10.76.1.4"

echo "== IP Gojo =="
ip -4 addr show
if ip -o -4 addr show | awk '{print $4}' | cut -d/ -f1 | grep -Fxq "$EXPECTED_IP"; then
    echo "OK: IP $EXPECTED_IP ditemukan."
else
    echo "ERROR: IP $EXPECTED_IP tidak ditemukan. Periksa konfigurasi interface/topologi."
    exit 1
fi

echo "== Tes koneksi ke Utahime =="
ping -c 3 -W 2 10.76.1.2

if command -v dig >/dev/null 2>&1; then
    dig @10.76.1.2 jujutsu.k25.com A +time=3 +tries=1
else
    echo "dig tidak tersedia; tes DNS dilewati."
fi
