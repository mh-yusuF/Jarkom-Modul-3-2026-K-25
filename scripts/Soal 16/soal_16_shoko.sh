#!/bin/sh
set -eu

cp /etc/bind/named.conf.options \
   /etc/bind/named.conf.options.bak-soal16

sed -i '/allow-query {/,/};/{
    /10\.76\.2\.0\/24/d
    /localhost;/a\
        10.76.2.0/24;
}' /etc/bind/named.conf.options

sed -i '/allow-recursion {/,/};/{
    /10\.76\.2\.0\/24/d
    /localhost;/a\
        10.76.2.0/24;
}' /etc/bind/named.conf.options

sed -i '/allow-query-cache {/,/};/{
    /10\.76\.2\.0\/24/d
    /localhost;/a\
        10.76.2.0/24;
}' /etc/bind/named.conf.options

named-checkconf
rndc reload