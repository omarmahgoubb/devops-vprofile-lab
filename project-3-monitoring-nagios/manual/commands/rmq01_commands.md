# rmq01 — RabbitMQ + NRPE agent

IP: `192.168.56.13` · CentOS Stream 9

```bash
vagrant ssh rmq01
```

---

## 1. RabbitMQ (same as Lecture 2)

Optional and slow. Skip if you want to save time:

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

---

## 2. NRPE agent (new in this lecture)

```bash
sudo dnf install -y nrpe nagios-plugins-all --skip-broken
```

Allow the Nagios server to connect:

```bash
echo "allowed_hosts=127.0.0.1,192.168.56.10" | sudo tee -a /etc/nagios/nrpe.cfg
```

```bash
sudo systemctl enable nrpe
sudo systemctl start nrpe
```

```bash
sudo firewall-cmd --add-port=5666/tcp --permanent
sudo firewall-cmd --reload
```

```bash
sudo systemctl status nrpe
```

---

## 3. CPU Load and RAM checks

Ping only tests reachability. CPU and RAM must run **on this VM**; NRPE sends the result to Nagios.

`nagios-plugins-all` is often skipped on Stream 9. Install the plugins you actually need:

```bash
sudo dnf install -y nagios-plugins-load nagios-plugins-swap nagios-plugins-disk nagios-plugins-procs
```

Confirm the CPU plugin exists:

```bash
ls /usr/lib64/nagios/plugins/check_load
```

EPEL has no `check_mem`. Add a small RAM check that uses **available** memory (so Linux cache does not fake a critical alert):

```bash
sudo tee /usr/lib64/nagios/plugins/check_ram <<'EOF'
#!/bin/bash
avail_pct=$(free | awk '/^Mem:/ {printf("%.0f", $7*100/$2)}')
warn=${1:-20}
crit=${2:-10}
if [ "$avail_pct" -le "$crit" ]; then
  echo "RAM CRITICAL - ${avail_pct}% available | ram_avail=${avail_pct}%;${warn};${crit}"
  exit 2
elif [ "$avail_pct" -le "$warn" ]; then
  echo "RAM WARNING - ${avail_pct}% available | ram_avail=${avail_pct}%;${warn};${crit}"
  exit 1
fi
echo "RAM OK - ${avail_pct}% available | ram_avail=${avail_pct}%;${warn};${crit}"
exit 0
EOF
sudo chmod +x /usr/lib64/nagios/plugins/check_ram
```

Register both checks in NRPE. These VMs have about **one CPU and 600 MB RAM**, so load thresholds are low:

```bash
sudo tee -a /etc/nagios/nrpe.cfg <<'EOF'
command[check_load]=/usr/lib64/nagios/plugins/check_load -w 1.0,1.0,1.0 -c 2.0,2.0,2.0
command[check_ram]=/usr/lib64/nagios/plugins/check_ram 20 10
EOF
```

```bash
sudo systemctl restart nrpe
```

Test locally (does not need the Nagios VM):

```bash
/usr/lib64/nagios/plugins/check_load -w 1.0,1.0,1.0 -c 2.0,2.0,2.0
/usr/lib64/nagios/plugins/check_ram
```
