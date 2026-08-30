#!/bin/bash
# db01 — MariaDB (Azure Custom data, runs once as root)
exec > /var/log/vprofile-customdata.log 2>&1
set -eux

sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config.d/01-localconfig.conf || true
printf 'PasswordAuthentication yes\n' > /etc/ssh/sshd_config.d/99-password.conf
systemctl restart sshd || true

if [ ! -f /swapfile ]; then
  dd if=/dev/zero of=/swapfile bs=1M count=2048
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

# Skip dnf update on B1s (OOM). Swap is required before dnf install.
dnf install epel-release -y
dnf install git mariadb-server -y
systemctl enable mariadb --now

mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'admin123'; FLUSH PRIVILEGES;"
mysql -u root -padmin123 -e "DELETE FROM mysql.user WHERE User='';"
mysql -u root -padmin123 -e "DROP DATABASE IF EXISTS test;"
mysql -u root -padmin123 -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
mysql -u root -padmin123 -e "FLUSH PRIVILEGES;"

mysql -u root -padmin123 -e "CREATE DATABASE IF NOT EXISTS accounts;"
mysql -u root -padmin123 -e "GRANT ALL PRIVILEGES ON accounts.* TO 'admin'@'%' IDENTIFIED BY 'admin123'; FLUSH PRIVILEGES;"

cd /root
if [ ! -d vprofile-project ]; then
  git clone -b main https://github.com/hkhcoder/vprofile-project.git
fi
mysql -u root -padmin123 accounts < /root/vprofile-project/src/main/resources/db_backup.sql

systemctl start firewalld
systemctl enable firewalld
firewall-cmd --zone=public --add-port=3306/tcp --permanent
firewall-cmd --reload
systemctl restart mariadb

echo "db01 custom data done"
