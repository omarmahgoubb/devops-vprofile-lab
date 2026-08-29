# mc01 — Memcached + NRPE agent

IP: `192.168.56.14` · CentOS Stream 9

```bash
vagrant ssh mc01
```

---

## 1. Memcached (same as Lecture 2)

Optional and slow. Skip if you want to save time:

```bash
sudo dnf update -y
```

Install the EPEL repo so extra packages become available:

```bash
sudo dnf install epel-release -y
```

Install the Memcached caching service:

```bash
sudo dnf install memcached -y
```

Enable Memcached to start automatically on boot:

```bash
sudo systemctl enable memcached
```

Start Memcached now:

```bash
sudo systemctl start memcached
```

Change the listen address from localhost (`127.0.0.1`) to all interfaces (`0.0.0.0`) so other VMs can reach the cache:

```bash
sudo sed -i 's/127.0.0.1/0.0.0.0/g' /etc/sysconfig/memcached
```

Restart Memcached so it listens on all interfaces:

```bash
sudo systemctl restart memcached
```

Start the firewall service:

```bash
sudo systemctl start firewalld
```

Enable the firewall to start automatically on boot:

```bash
sudo systemctl enable firewalld
```

Allow Memcached TCP traffic on port 11211 (runtime rule):

```bash
sudo firewall-cmd --add-port=11211/tcp
```

Save the current runtime firewall rules so they survive a reboot:

```bash
sudo firewall-cmd --runtime-to-permanent
```

Allow Memcached UDP traffic on port 11111 (runtime rule):

```bash
sudo firewall-cmd --add-port=11111/udp
```

Save the UDP rule permanently as well:

```bash
sudo firewall-cmd --runtime-to-permanent
```

Start a Memcached daemon listening on TCP 11211 and UDP 11111 as the `memcached` user:

```bash
sudo memcached -p 11211 -U 11111 -u memcached -d
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
