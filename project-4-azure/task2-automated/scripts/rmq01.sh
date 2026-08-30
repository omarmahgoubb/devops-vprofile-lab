#!/bin/bash
# rmq01 — RabbitMQ (Azure Custom data, runs once as root)
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
dnf install wget -y
dnf -y install centos-release-rabbitmq-38
dnf --enablerepo=centos-rabbitmq-38 -y install rabbitmq-server
systemctl enable --now rabbitmq-server

echo "[{rabbit, [{loopback_users, []}]}]." > /etc/rabbitmq/rabbitmq.config
rabbitmqctl add_user test test || true
rabbitmqctl set_user_tags test administrator
systemctl restart rabbitmq-server

systemctl start firewalld
systemctl enable firewalld
firewall-cmd --add-port=5672/tcp --permanent
firewall-cmd --reload
systemctl enable --now rabbitmq-server

echo "rmq01 custom data done"
