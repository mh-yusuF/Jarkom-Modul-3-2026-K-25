#!/bin/bash
set -e

if ! command -v dig >/dev/null 2>&1; then
    apt-get update
    apt-get install -y dnsutils iputils-ping
fi

echo "=== Uji DNS Master: Utahime ==="
dig @10.76.1.2 gojo.jujutsu.k25.com A +noall +answer

echo
echo "=== Uji DNS Slave: Shoko ==="
dig @10.76.1.3 gojo.jujutsu.k25.com A +noall +answer

echo
echo "=== Uji SOA Master ==="
dig @10.76.1.2 jujutsu.k25.com SOA +noall +answer

echo
echo "=== Uji SOA Slave ==="
dig @10.76.1.3 jujutsu.k25.com SOA +noall +answer
