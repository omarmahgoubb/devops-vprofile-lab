# rmq01 — RabbitMQ setup

SSH from the Windows host into the rmq01 VM:

```bash
vagrant ssh rmq01
```

Update all installed packages on CentOS Stream 9 to the latest versions:

```bash
sudo dnf update -y
```

Install the EPEL repo so extra packages become available:

```bash
sudo dnf install epel-release -y
```

Install wget (used to fetch packages if needed):

```bash
sudo dnf install wget -y
```

Add the CentOS RabbitMQ 3.8 repository:

```bash
sudo dnf -y install centos-release-rabbitmq-38
```

Install RabbitMQ server from that repository:

```bash
sudo dnf --enablerepo=centos-rabbitmq-38 -y install rabbitmq-server
```

Enable RabbitMQ to start on boot, and start it immediately:

```bash
sudo systemctl enable --now rabbitmq-server
```

Allow non-localhost users to connect (disable the default loopback-only restriction):

```bash
sudo sh -c 'echo "[{rabbit, [{loopback_users, []}]}]." > /etc/rabbitmq/rabbitmq.config'
```

Create an application user named `test` with password `test`:

```bash
sudo rabbitmqctl add_user test test
```

Give that user administrator rights:

```bash
sudo rabbitmqctl set_user_tags test administrator
```

Restart RabbitMQ so the config and user changes take effect:

```bash
sudo systemctl restart rabbitmq-server
```

Start the firewall service:

```bash
sudo systemctl start firewalld
```

Enable the firewall to start automatically on boot:

```bash
sudo systemctl enable firewalld
```

Allow AMQP traffic on port 5672 (the port the Java app uses to talk to RabbitMQ):

```bash
sudo firewall-cmd --add-port=5672/tcp
```

Save the firewall rule so it survives a reboot:

```bash
sudo firewall-cmd --runtime-to-permanent
```

Start RabbitMQ (safe to run again if it is already running):

```bash
sudo systemctl start rabbitmq-server
```

Enable RabbitMQ to start on boot (safe to run again if already enabled):

```bash
sudo systemctl enable rabbitmq-server
```
