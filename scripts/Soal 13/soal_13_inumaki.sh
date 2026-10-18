#!/bin/bash
set -e

apt-get update
apt-get install -y mariadb-server mariadb-client

mkdir -p /var/log/mysql /run/mysqld
chown mysql:mysql /var/log/mysql /run/mysqld
chmod 750 /var/log/mysql
chmod 755 /run/mysqld

cat > /etc/mysql/mariadb.conf.d/60-replication.cnf <<'EOF'
[mysqld]
server-id = 2
relay_log = /var/log/mysql/mariadb-relay-bin
read_only = ON
bind-address = 0.0.0.0
EOF

service mariadb restart

until mariadb -e "SELECT 1" >/dev/null 2>&1; do
    sleep 1
done

echo "Konfigurasi Slave sudah dipasang."
echo "Periksa status replikasi dengan:"
echo "mariadb -e 'SHOW SLAVE STATUS\G'"
echo
echo "Jika replikasi sebelumnya sudah berhasil, jangan konfigurasi ulang."
echo "Jika ini konfigurasi awal, isi File dan Position dari Yaga pada"
echo "perintah CHANGE MASTER TO di bawah ini."