# Update the system
# echo "Updating the system..."
# sudo apt update -y
# sudo apt-get update -y
# echo "System update completed."

export DEBIAN_FRONTEND=noninteractive

# Wait until hostmanager has published app01 (Nginx upstream needs it)
echo "Waiting for app01 to resolve..."
for i in $(seq 1 60); do
  if getent hosts app01 >/dev/null 2>&1; then
    echo "app01 resolved."
    break
  fi
  sleep 2
done

# Install Nginx
echo "Installing Nginx..."
sudo apt-get install -y nginx
echo "Nginx installed."

# Configure Nginx with a custom site
echo "Configuring Nginx for vproapp..."
sudo bash -c 'cat > /etc/nginx/sites-available/vproapp <<EOF
upstream vproapp {
    server app01:8080;
}
server {
    listen 80;
    location / {
        proxy_pass http://vproapp;
    }
}
EOF'
echo "Nginx configuration for vproapp created."

# Remove the default site and enable the new configuration
echo "Removing default Nginx site and enabling vproapp..."
sudo rm -f /etc/nginx/sites-enabled/default
sudo ln -sf /etc/nginx/sites-available/vproapp /etc/nginx/sites-enabled/vproapp
echo "Default site removed, and vproapp enabled."

# Restart Nginx; retry if app01 is not in hosts yet
echo "Restarting Nginx..."
for i in $(seq 1 15); do
  if sudo nginx -t && sudo systemctl restart nginx; then
    echo "Nginx restarted successfully."
    break
  fi
  echo "Nginx not ready yet (app01 DNS?), retrying..."
  sleep 2
done

# NRPE agent (Ubuntu) + CPU/RAM
echo "Installing NRPE and plugins..."
# sudo apt-get update -y
sudo apt-get install -y nagios-nrpe-server nagios-plugins nagios-plugins-basic nagios-plugins-standard

echo "Allowing Nagios server (192.168.56.10) in nrpe.cfg..."
if [ -f /etc/nagios/nrpe.cfg ]; then
  if grep -qE '^#?allowed_hosts=' /etc/nagios/nrpe.cfg; then
    sudo sed -i -E 's/^#?allowed_hosts=.*/allowed_hosts=127.0.0.1,::1,192.168.56.10/' /etc/nagios/nrpe.cfg
  else
    echo "allowed_hosts=127.0.0.1,::1,192.168.56.10" | sudo tee -a /etc/nagios/nrpe.cfg
  fi
fi

sudo tee /usr/lib/nagios/plugins/check_ram >/dev/null <<'EOF'
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

# Ubuntu loads /etc/nagios/nrpe.d/; write zzz_ so it wins over package samples.
# Do not grep nrpe.cfg for command[check_load] (commented example would skip this).
NRPE_CMD='command[check_load]=/usr/lib/nagios/plugins/check_load -w 1.0,1.0,1.0 -c 2.0,2.0,2.0
command[check_ram]=/usr/lib/nagios/plugins/check_ram 20 10
'
sudo mkdir -p /etc/nagios/nrpe.d /etc/nrpe.d
echo "$NRPE_CMD" | sudo tee /etc/nagios/nrpe.d/zzz_vprofile.cfg >/dev/null
echo "$NRPE_CMD" | sudo tee /etc/nrpe.d/zzz_vprofile.cfg >/dev/null

sudo systemctl enable nagios-nrpe-server
sudo systemctl restart nagios-nrpe-server
sudo ufw allow 5666/tcp || true

echo "Provisioning for web01 is complete!"
