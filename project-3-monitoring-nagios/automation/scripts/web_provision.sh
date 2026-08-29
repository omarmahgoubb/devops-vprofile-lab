# Update the system
# echo "Updating the system..."
# sudo apt update -y
# sudo apt-get update -y
# echo "System update completed."

# Wait until hostmanager has published app01 (Nginx upstream needs it)
echo "Waiting for app01 to resolve..."
for i in $(seq 1 30); do
  if getent hosts app01 >/dev/null 2>&1; then
    echo "app01 resolved."
    break
  fi
  sleep 2
done

# Install Nginx
echo "Installing Nginx..."
sudo apt install nginx -y
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
sudo rm -rf /etc/nginx/sites-enabled/default
sudo ln -sf /etc/nginx/sites-available/vproapp /etc/nginx/sites-enabled/vproapp
echo "Default site removed, and vproapp enabled."

# Restart Nginx to apply changes
echo "Restarting Nginx..."
sudo systemctl restart nginx
echo "Nginx restarted successfully."

# NRPE agent (Ubuntu) + CPU/RAM
echo "Installing NRPE and plugins..."
# sudo apt-get update -y
sudo apt-get install -y nagios-nrpe-server nagios-plugins nagios-plugins-basic nagios-plugins-standard

if ! grep -q '192.168.56.10' /etc/nagios/nrpe.cfg 2>/dev/null; then
  echo "allowed_hosts=127.0.0.1,192.168.56.10" | sudo tee -a /etc/nagios/nrpe.cfg
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

if ! grep -q 'command\[check_load\]' /etc/nagios/nrpe.cfg; then
  sudo tee -a /etc/nagios/nrpe.cfg >/dev/null <<'EOF'
command[check_load]=/usr/lib/nagios/plugins/check_load -w 1.0,1.0,1.0 -c 2.0,2.0,2.0
command[check_ram]=/usr/lib/nagios/plugins/check_ram 20 10
EOF
fi

sudo systemctl enable nagios-nrpe-server
sudo systemctl restart nagios-nrpe-server
sudo ufw allow 5666/tcp || true

echo "Provisioning for web01 is complete!"
