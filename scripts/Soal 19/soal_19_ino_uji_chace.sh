#!/bin/sh

URL="http://jujutsu.k25.com/?cachetest=19003"

echo "=== Request pertama: diharapkan MISS ==="
curl -s -D - -o /dev/null "$URL" | grep -i -E 'HTTP/|X-Cache-Status'

echo
echo "=== Request kedua: diharapkan HIT ==="
curl -s -D - -o /dev/null "$URL" | grep -i -E 'HTTP/|X-Cache-Status'