# db01 — MariaDB + NRPE agent

IP: `192.168.56.15` · CentOS Stream 9

Start the VM from the `manualDeployment` folder, then SSH in:

```bash
vagrant ssh db01
```

---

## 1. MariaDB (same as Lecture 2)

Optional and slow. Skip if you want to save time (you skipped it in the automated lab):

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

Create the application database **before** importing the dump:

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

---

## 2. NRPE agent (new in this lecture)

Install NRPE and Nagios plugins so the Nagios server can run checks on this VM. `--skip-broken` skips plugins that do not exist on CentOS Stream 9:

```bash
sudo dnf install -y nrpe nagios-plugins-all --skip-broken
```

Allow the Nagios server (`192.168.56.10`) to connect to this agent:

```bash
echo "allowed_hosts=127.0.0.1,192.168.56.10" | sudo tee -a /etc/nagios/nrpe.cfg
```

Enable and start the NRPE service (CentOS service name is `nrpe`):

```bash
sudo systemctl enable nrpe
sudo systemctl start nrpe
```

Open the NRPE port so the Nagios server can reach the agent:

```bash
sudo firewall-cmd --add-port=5666/tcp --permanent
sudo firewall-cmd --reload
```

Confirm the agent is listening:

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
