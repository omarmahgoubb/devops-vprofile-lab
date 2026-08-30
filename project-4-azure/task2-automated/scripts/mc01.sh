#!/bin/bash
# mc01 — Memcached (Azure Custom data, runs once as root)
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

dnf install epel-release -y
dnf install memcached -y
systemctl enable memcached
systemctl start memcached
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/sysconfig/memcached
systemctl restart memcached

systemctl start firewalld
systemctl enable firewalld
firewall-cmd --add-port=11211/tcp --permanent
firewall-cmd --add-port=11111/udp --permanent
firewall-cmd --reload
memcached -p 11211 -U 11111 -u memcached -d || true

echo "mc01 custom data done"
