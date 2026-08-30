#!/bin/bash
# NRPE agent + CPU/RAM checks for CentOS Stream 9 clients.
# Called after the service provision script (db/mc/rmq/app).

# sudo dnf update -y

echo "Installing NRPE and plugins..."
sudo dnf install -y nrpe nagios-plugins-all --skip-broken
sudo dnf install -y nagios-plugins-load nagios-plugins-swap nagios-plugins-disk nagios-plugins-procs

echo "Allowing Nagios server (192.168.56.10) in nrpe.cfg..."
if grep -qE '^#?allowed_hosts=' /etc/nagios/nrpe.cfg 2>/dev/null; then
  sudo sed -i -E 's/^#?allowed_hosts=.*/allowed_hosts=127.0.0.1,::1,192.168.56.10/' /etc/nagios/nrpe.cfg
else
  echo "allowed_hosts=127.0.0.1,::1,192.168.56.10" | sudo tee -a /etc/nagios/nrpe.cfg
fi

echo "Installing check_ram plugin..."
sudo tee /usr/lib64/nagios/plugins/check_ram >/dev/null <<'EOF'
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

# NRPE 4 only loads command[] from include_dir (/etc/nrpe.d/).
# Do not grep nrpe.cfg for command[check_load] — the stock file has that
# string in a comment, which skipped writing check_ram on first automate.
# zzz_ prefix so this file loads last and overrides plugin package defaults.
sudo mkdir -p /etc/nrpe.d
sudo tee /etc/nrpe.d/zzz_vprofile.cfg >/dev/null <<'EOF'
command[check_load]=/usr/lib64/nagios/plugins/check_load -w 1.0,1.0,1.0 -c 2.0,2.0,2.0
command[check_ram]=/usr/lib64/nagios/plugins/check_ram 20 10
EOF

sudo systemctl enable nrpe
sudo systemctl restart nrpe

sudo systemctl enable firewalld
sudo systemctl start firewalld
sudo firewall-cmd --add-port=5666/tcp --permanent
sudo firewall-cmd --reload

echo "NRPE agent (CPU/RAM) configured."
