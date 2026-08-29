# db01 — MariaDB setup

SSH from the Windows host into the db01 VM:

```bash
vagrant ssh db01
```

Update all installed packages on CentOS Stream 9 to the latest versions:

```bash
sudo dnf update -y
```

Install the EPEL repo so extra packages (not in the default repos) become available:

```bash
sudo dnf install epel-release -y
```

Install Git (to clone the app repo) and MariaDB (MySQL-compatible database server):

```bash
sudo dnf install git mariadb-server -y
```

Enable MariaDB to start on boot, and start it immediately:

```bash
sudo systemctl enable mariadb --now
```

Open the MariaDB shell as the local root user (no password yet):

```bash
sudo mysql
```

Switch to the built-in mysql system database:

```sql
USE mysql
```

Set a password for the local root user so root is no longer passwordless:

```sql
ALTER USER 'root'@'localhost' IDENTIFIED BY 'admin123';
```

Apply the privilege/password change immediately:

```sql
FLUSH PRIVILEGES;
```

Leave the MariaDB shell and return to the Linux prompt:

```sql
exit
```

Run the interactive security wizard (hardens the default MariaDB install):

```bash
sudo mysql_secure_installation
```

When prompted, enter these answers:

| Prompt | Answer | Why |
|---|---|---|
| Current root password | `admin123` | The password you just set |
| Switch to unix_socket authentication? | `n` | Keep password login |
| Change the root password? | `n` | You already set `admin123` |
| Remove anonymous users? | `y` | They are a security risk |
| Disallow root login remotely? | `n` | Keep it allowed for this lab |
| Remove the test database? | `y` | It is not needed |
| Reload privilege tables now? | `y` | Apply the wizard changes |

Log in to MariaDB as root using the password (no space after `-p`):

```bash
mysql -u root -padmin123
```

Create the application database that the Java app will use:

```sql
create database accounts;
```

Create user `admin` (password `admin123`) that can connect from any host (`%`) and fully manage the accounts database:

```sql
GRANT ALL PRIVILEGES ON accounts.* TO 'admin'@'%' IDENTIFIED BY 'admin123';
```

Apply the new user privileges immediately:

```sql
FLUSH PRIVILEGES;
```

Leave the MariaDB shell:

```sql
exit
```

Clone the vprofile app source (main branch) so you can import its SQL dump:

```bash
git clone -b main https://github.com/hkhcoder/vprofile-project.git
```

Import the app's backup SQL into the accounts database (creates tables and sample data):

```bash
mysql -u root -padmin123 accounts < vprofile-project/src/main/resources/db_backup.sql
```

Restart MariaDB so it picks up the imported data cleanly:

```bash
sudo systemctl restart mariadb
```

Start the firewall service (needed to open the DB port to other VMs):

```bash
sudo systemctl start firewalld
```

Enable the firewall to start automatically on boot:

```bash
sudo systemctl enable firewalld
```

Show which firewall zone is active (usually `public`) so you know where to add the rule:

```bash
sudo firewall-cmd --get-active-zones
```

Allow incoming MySQL/MariaDB traffic (TCP 3306) permanently in the public zone:

```bash
sudo firewall-cmd --zone=public --add-port=3306/tcp --permanent
```

Reload the firewall so the permanent 3306 rule becomes active now:

```bash
sudo firewall-cmd --reload
```

Restart MariaDB one last time after opening the firewall:

```bash
sudo systemctl restart mariadb
```
