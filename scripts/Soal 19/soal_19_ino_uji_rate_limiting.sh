#!/bin/sh

echo "=== Pengujian 50 request ke /api ==="

seq 1 50 | xargs -P 50 -I {} sh -c \
'curl -s -o /dev/null -w "%{http_code}\n" http://jujutsu.k25.com/api' \
| sort | uniq -c