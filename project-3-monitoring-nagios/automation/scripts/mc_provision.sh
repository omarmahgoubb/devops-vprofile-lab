# Update the system
# echo "Updating the system..."
# sudo dnf update -y
# echo "System update completed."

# Install epel-release
echo "Installing epel-release..."
sudo dnf install epel-release -y
echo "epel-release installed."

# Install memcached
echo "Installing memcached..."
sudo dnf install memcached -y
echo "memcached installed."

# Enable and start memcached
echo "Enabling and starting memcached service..."
sudo systemctl enable memcached
sudo systemctl start memcached
echo "memcached service enabled and started."

# Configure memcached to listen on all interfaces
echo "Configuring memcached to listen on all interfaces..."
sudo sed -i 's/127.0.0.1/0.0.0.0/g' /etc/sysconfig/memcached
sudo systemctl restart memcached
echo "memcached configuration updated and service restarted."

# Start and enable the firewall
echo "Starting and enabling the firewall..."
sudo systemctl start firewalld
sudo systemctl enable firewalld
echo "Firewall started and enabled."

# Configure the firewall for memcached
echo "Configuring the firewall for memcached..."
sudo firewall-cmd --add-port=11211/tcp --permanent
sudo firewall-cmd --add-port=11111/udp --permanent
sudo firewall-cmd --reload
echo "Firewall configured for memcached."

# Start memcached with specified ports and user
echo "Starting memcached with custom ports..."
sudo memcached -p 11211 -U 11111 -u memcached -d
echo "memcached started with custom ports."

echo "Provisioning for mc01 is complete!"