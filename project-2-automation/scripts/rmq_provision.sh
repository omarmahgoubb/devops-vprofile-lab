# Update the system
echo "Updating the system..."
# sudo dnf update -y
echo "System update completed."

# Install epel-release
echo "Installing epel-release..."
sudo dnf install epel-release -y
echo "epel-release installed."

# Install wget
echo "Installing wget..."
sudo dnf install wget -y
echo "wget installed."

# Enable RabbitMQ repository and install RabbitMQ server
echo "Enabling RabbitMQ repository and installing RabbitMQ server..."
sudo dnf -y install centos-release-rabbitmq-38
sudo dnf --enablerepo=centos-rabbitmq-38 -y install rabbitmq-server
echo "RabbitMQ server installed."

# Enable and start RabbitMQ server
echo "Enabling and starting RabbitMQ server..."
sudo systemctl enable --now rabbitmq-server
echo "RabbitMQ server enabled and started."

# Configure RabbitMQ to allow external access
echo "Configuring RabbitMQ to allow external access..."
sudo sh -c 'echo "[{rabbit, [{loopback_users, []}]}]." > /etc/rabbitmq/rabbitmq.config'
echo "RabbitMQ configuration updated."

# Add a RabbitMQ user and assign administrator role
echo "Adding RabbitMQ user 'test' and assigning administrator role..."
sudo rabbitmqctl add_user test test
sudo rabbitmqctl set_user_tags test administrator
echo "RabbitMQ user 'test' added and configured."

# Restart RabbitMQ server
echo "Restarting RabbitMQ server..."
sudo systemctl restart rabbitmq-server
echo "RabbitMQ server restarted."

# Start and enable the firewall
echo "Starting and enabling the firewall..."
sudo systemctl start firewalld
sudo systemctl enable firewalld
echo "Firewall started and enabled."

# Configure the firewall for RabbitMQ
echo "Configuring the firewall for RabbitMQ..."
sudo firewall-cmd --add-port=5672/tcp --permanent
sudo firewall-cmd --reload
echo "Firewall configured for RabbitMQ."

# Start and enable RabbitMQ server again
echo "Ensuring RabbitMQ server is started and enabled..."
sudo systemctl start rabbitmq-server
sudo systemctl enable rabbitmq-server
echo "RabbitMQ server is running and enabled at startup."

echo "Provisioning for rmq01 is complete!"