# web01 — Nginx reverse proxy + NRPE agent

IP: `192.168.56.11` · Ubuntu 22.04

Bring `app01` up **first**. Nginx proxies to `app01:8080`. If `app01` is not in `/etc/hosts` yet, `systemctl restart nginx` fails with `host not found in upstream`. First SSH can fail; `vagrant reload web01` usually works.

```bash
vagrant ssh web01
```

---

## 1. Nginx (same as Lecture 2)

Update the Ubuntu package lists:

```bash
sudo apt update
```

Install Nginx (the reverse proxy in front of Tomcat):

```bash
sudo apt install nginx -y
```

Confirm `app01` resolves before writing the site config:

```bash
getent hosts app01
```

You should see `192.168.56.12`. If it is empty, wait a minute or run `vagrant hostmanager` from the Windows host (Administrator PowerShell), then try again.

Create a new Nginx site config for the vprofile app:

```bash
sudo vim /etc/nginx/sites-available/vproapp
```

In vim: press `i`, paste the config below, then press `Esc` and type `:wq`.

This sends all HTTP traffic on port 80 to Tomcat on `app01:8080`:

```nginx
upstream vproapp {
server app01:8080;
}
server {
listen 80;
location / {
proxy_pass http://vproapp;
}
}
```

Remove the default Nginx site so it does not conflict with yours:

```bash
sudo rm -rf /etc/nginx/sites-enabled/default
```

Enable the vproapp site by linking it into `sites-enabled`:

```bash
sudo ln -s /etc/nginx/sites-available/vproapp /etc/nginx/sites-enabled/vproapp
```

Restart Nginx so the new reverse-proxy config is active:

```bash
sudo systemctl restart nginx
```

From Windows, open `http://192.168.56.11` (or `http://web01`). You should see the vprofile app, not a Tomcat 404.

---

## 2. NRPE agent (new in this lecture — Ubuntu packages)

Ubuntu uses different package and service names than CentOS.

Install the NRPE server and plugins (including load/CPU):

```bash
sudo apt-get update -y
sudo apt-get install -y nagios-nrpe-server nagios-plugins nagios-plugins-basic nagios-plugins-standard
```

Allow the Nagios server (`192.168.56.10`) to connect:

```bash
sudo bash -c 'echo "allowed_hosts=127.0.0.1,192.168.56.10" >> /etc/nagios/nrpe.cfg'
```

Enable and restart the NRPE service (Ubuntu service name is `nagios-nrpe-server`, not `nrpe`):

```bash
sudo systemctl enable nagios-nrpe-server
sudo systemctl restart nagios-nrpe-server
```

Allow NRPE on the firewall. UFW is often inactive on this box; the command is still safe to run:

```bash
sudo ufw allow 5666/tcp
```

```bash
sudo systemctl status nagios-nrpe-server
```

---

## 3. CPU Load and RAM checks

Ubuntu plugin path is `/usr/lib/nagios/plugins/` (not `lib64`). Service name is `nagios-nrpe-server`.

Confirm the CPU plugin exists:

```bash
ls /usr/lib/nagios/plugins/check_load
```

Add a RAM check that uses **available** memory:

```bash
sudo tee /usr/lib/nagios/plugins/check_ram <<'EOF'
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
sudo chmod +x /usr/lib/nagios/plugins/check_ram
```

Register both checks in NRPE:

```bash
sudo tee -a /etc/nagios/nrpe.cfg <<'EOF'
command[check_load]=/usr/lib/nagios/plugins/check_load -w 1.0,1.0,1.0 -c 2.0,2.0,2.0
command[check_ram]=/usr/lib/nagios/plugins/check_ram 20 10
EOF
```

```bash
sudo systemctl restart nagios-nrpe-server
```

Test locally:

```bash
/usr/lib/nagios/plugins/check_load -w 1.0,1.0,1.0 -c 2.0,2.0,2.0
/usr/lib/nagios/plugins/check_ram
```
