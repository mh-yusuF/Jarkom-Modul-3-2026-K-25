#!/bin/bash
set -e

# Install MariaDB
apt-get update
apt-get install -y mariadb-server mariadb-client

# Siapkan direktori log dan runtime
mkdir -p /var/log/mysql /run/mysqld
chown mysql:mysql /var/log/mysql /run/mysqld
chmod 750 /var/log/mysql
chmod 755 /run/mysqld

# Konfigurasi Master
cat > /etc/mysql/mariadb.conf.d/60-replication.cnf <<'EOF'
[mysqld]
server-id = 1
log_bin = /var/log/mysql/mariadb-bin
binlog_format = ROW
bind-address = 0.0.0.0
EOF

service mariadb restart

# Tunggu service siap
until mariadb -e "SELECT 1" >/dev/null 2>&1; do
    sleep 1
done

# Database, tabel, akun replikasi, dan akun klien
mariadb <<'SQL'
CREATE DATABASE IF NOT EXISTS db_shibuya_K25;

CREATE TABLE IF NOT EXISTS db_shibuya_K25.request_logs (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    source_node VARCHAR(100) NOT NULL,
    request_detail TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE USER IF NOT EXISTS 'replicator'@'10.76.4.8'
IDENTIFIED BY 'replicatorK25';

GRANT REPLICATION SLAVE ON *.*
TO 'replicator'@'10.76.4.8';

CREATE USER IF NOT EXISTS 'dbuser'@'10.76.3.%'
IDENTIFIED BY 'databaseK25';

CREATE USER IF NOT EXISTS 'dbuser'@'10.76.4.%'
IDENTIFIED BY 'databaseK25';

GRANT ALL PRIVILEGES ON db_shibuya_K25.*
TO 'dbuser'@'10.76.3.%';

GRANT ALL PRIVILEGES ON db_shibuya_K25.*
TO 'dbuser'@'10.76.4.%';

FLUSH PRIVILEGES;
SQL

echo
echo "=== Status binary logging ==="
mariadb -e "SHOW VARIABLES LIKE 'log_bin';"

echo
echo "=== Status Master ==="
mariadb -e "SHOW MASTER STATUS\G"

echo
echo "=== Tabel request_logs ==="
mariadb -e "DESCRIBE db_shibuya_K25.request_logs;"

echo
echo "=== Selesai ==="
echo "CATATAN UNTUK INUMAKI:"
echo "1. Catat File dan Position dari SHOW MASTER STATUS di atas."
echo "2. Gunakan nilai tersebut pada MASTER_LOG_FILE dan MASTER_LOG_POS"
echo "   di skrip Inumaki jika melakukan konfigurasi replikasi awal/ulang."
echo "3. Jangan jalankan CHANGE MASTER TO lagi jika replikasi saat ini"
echo "   sudah berjalan normal; periksa SHOW SLAVE STATUS terlebih dahulu."
echo "4. Sesuaikan password pada skrip Inumaki dengan password replicator"
echo "   yang ditetapkan di Master."