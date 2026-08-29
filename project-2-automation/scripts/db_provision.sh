# Update the system
echo "Updating the system..."
# sudo dnf update -y
echo "System update completed."

# Install necessary packages
echo "Installing epel-release..."
sudo dnf install epel-release -y
echo "epel-release installed."

echo "Installing git and mariadb-server..."
sudo dnf install git mariadb-server -y
echo "git and mariadb-server installed."

# Enable and start MariaDB service
echo "Enabling and starting MariaDB service..."
sudo systemctl enable mariadb --now
echo "MariaDB service enabled and started."

# Configure MariaDB root user password
echo "Configuring MariaDB root user password..."
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'admin123'; FLUSH PRIVILEGES;"
echo "MariaDB root user password configured."

# Secure MariaDB installation
echo "Securing MariaDB installation..."
sudo mysql_secure_installation <<EOF
admin123
n
n
y
n
y
y
EOF
echo "MariaDB installation secured."

# Create the accounts database and set up privileges
echo "Creating the 'accounts' database and setting up privileges..."
sudo mysql -u root -padmin123 -e "CREATE DATABASE accounts;"
sudo mysql -u root -padmin123 -e "GRANT ALL PRIVILEGES ON accounts.* TO 'admin'@'%' IDENTIFIED BY 'admin123'; FLUSH PRIVILEGES;"
echo "'accounts' database and user privileges configured."

# Clone the project repository
echo "Cloning the project repository..."
git clone -b main https://github.com/hkhcoder/vprofile-project.git
echo "Project repository cloned."

# Import the database backup
echo "Importing the database backup..."
sudo mysql -u root -padmin123 accounts < vprofile-project/src/main/resources/db_backup.sql
echo "Database backup imported."

# Restart MariaDB service
echo "Restarting MariaDB service..."
sudo systemctl restart mariadb
echo "MariaDB service restarted."

# Start and enable the firewall
echo "Starting and enabling the firewall..."
sudo systemctl start firewalld
sudo systemctl enable firewalld
echo "Firewall started and enabled."

# Configure the firewall for MariaDB
echo "Configuring the firewall for MariaDB..."
sudo firewall-cmd --zone=public --add-port=3306/tcp --permanent
sudo firewall-cmd --reload
echo "Firewall configured for MariaDB."

# Restart MariaDB service again
echo "Restarting MariaDB service..."
sudo systemctl restart mariadb
echo "MariaDB service restarted."

echo "Provisioning for db01 is complete!"