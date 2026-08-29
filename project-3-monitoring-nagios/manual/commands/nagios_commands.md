# nagios — Nagios Core server

IP: `192.168.56.10` · CentOS Stream 9 · 1024 MB RAM

Bring the five app VMs up and install their services **and** NRPE agents first. This VM only monitors them.

```bash
vagrant ssh nagios
```

---

## 1. Install Nagios Core, plugins, and Apache

Install EPEL, then Nagios, plugins, NRPE (so this host can call `check_nrpe`), and Apache (the web UI):

```bash
sudo yum install -y epel-release
sudo yum install -y nagios nagios-plugins-all nrpe nagios-plugins-nrpe httpd --skip-broken
```

`nagios-plugins-nrpe` installs `/usr/lib64/nagios/plugins/check_nrpe` on **this** server. The `nrpe` package is the agent. Without `nagios-plugins-nrpe`, CPU/RAM service checks cannot run. If you already installed packages, run this now:

```bash
sudo yum install -y nagios-plugins-nrpe
```

Enable and start Apache and Nagios:

```bash
sudo systemctl enable httpd
sudo systemctl start httpd
sudo systemctl enable nagios
sudo systemctl start nagios
```

Open HTTP (web UI) and NRPE on the firewall:

```bash
sudo systemctl start firewalld
sudo firewall-cmd --add-service=http --permanent
sudo firewall-cmd --add-port=5666/tcp --permanent
sudo firewall-cmd --reload
```

Set the web UI password. The automated script skips this; you need it to log in. User is `nagiosadmin`:

```bash
sudo htpasswd -c /etc/nagios/passwd nagiosadmin
```

Choose a password (this lab often uses `admin123`).

From Windows, open:

`http://192.168.56.10/nagios`

Login: `nagiosadmin` / the password you just set. Hosts will be empty until you add them below.

---

## 2. Define the five hosts

Create `/etc/nagios/objects/clients.cfg`:

```bash
sudo vim /etc/nagios/objects/clients.cfg
```

Paste:

```
define host {
  use             linux-server
  host_name       db01
  address         192.168.56.15
}

define host {
  use             linux-server
  host_name       mc01
  address         192.168.56.14
}

define host {
  use             linux-server
  host_name       rmq01
  address         192.168.56.13
}

define host {
  use             linux-server
  host_name       app01
  address         192.168.56.12
}

define host {
  use             linux-server
  host_name       web01
  address         192.168.56.11
}
```

---

## 3. Define ping, CPU, and RAM services

Ping does **not** need NRPE. It is run from this Nagios VM to each IP. CPU Load and RAM use `check_nrpe` and must be defined on each client first.

Create `/etc/nagios/objects/services.cfg`:

```bash
sudo vim /etc/nagios/objects/services.cfg
```

Paste:

```
define service{
    use                     generic-service
    host_name               db01
    service_description     Ping Check
    check_command           check_ping!100.0,20%!500.0,60%
    max_check_attempts      4
    check_interval          5
    retry_interval          1
    check_period            24x7
    notification_interval   30
    notification_period     24x7
}

define service{
    use                     generic-service
    host_name               mc01
    service_description     Ping Check
    check_command           check_ping!100.0,20%!500.0,60%
    max_check_attempts      4
    check_interval          5
    retry_interval          1
    check_period            24x7
    notification_interval   30
    notification_period     24x7
}

define service{
    use                     generic-service
    host_name               rmq01
    service_description     Ping Check
    check_command           check_ping!100.0,20%!500.0,60%
    max_check_attempts      4
    check_interval          5
    retry_interval          1
    check_period            24x7
    notification_interval   30
    notification_period     24x7
}

define service{
    use                     generic-service
    host_name               app01
    service_description     Ping Check
    check_command           check_ping!100.0,20%!500.0,60%
    max_check_attempts      4
    check_interval          5
    retry_interval          1
    check_period            24x7
    notification_interval   30
    notification_period     24x7
}

define service{
    use                     generic-service
    host_name               web01
    service_description     Ping Check
    check_command           check_ping!100.0,20%!500.0,60%
    max_check_attempts      4
    check_interval          5
    retry_interval          1
    check_period            24x7
    notification_interval   30
    notification_period     24x7
}

define service{
    use                     generic-service
    host_name               db01,mc01,rmq01,app01,web01
    service_description     CPU Load
    check_command           check_nrpe!check_load
}

define service{
    use                     generic-service
    host_name               db01,mc01,rmq01,app01,web01
    service_description     RAM
    check_command           check_nrpe!check_ram
}
```

`check_nrpe!check_load` means: ask that host’s NRPE agent to run the command named `check_load` in **its** `nrpe.cfg`. Same for `check_ram`. Those commands must exist on every client (section 3 of each machine file).

---

## 4. Add the `check_nrpe` command

This lets Nagios call the agent for CPU Load and RAM. Ping does not use NRPE.

```bash
sudo vim /etc/nagios/objects/commands.cfg
```

Go to the end of the file and add:

```
define command {
    command_name    check_nrpe
    command_line    $USER1$/check_nrpe -H $HOSTADDRESS$ -c $ARG1$
}
```

`$USER1$` and `$HOSTADDRESS$` must stay exactly like that (Nagios macros). Do not replace them with paths or IPs by hand.

---

## 5. Tell Nagios to load the new files

```bash
echo "cfg_file=/etc/nagios/objects/clients.cfg" | sudo tee -a /etc/nagios/nagios.cfg
echo "cfg_file=/etc/nagios/objects/services.cfg" | sudo tee -a /etc/nagios/nagios.cfg
```

Validate the config **before** restarting. Fix any errors it prints:

```bash
sudo nagios -v /etc/nagios/nagios.cfg
```

```bash
sudo systemctl restart nagios
```

---

## 6. Test the agents from this VM

If `check_nrpe` is missing (`No such file or directory`), install it first:

```bash
sudo yum install -y nagios-plugins-nrpe
ls /usr/lib64/nagios/plugins/check_nrpe
```

Then try:

```bash
/usr/lib64/nagios/plugins/check_nrpe -H 192.168.56.15
/usr/lib64/nagios/plugins/check_nrpe -H 192.168.56.14
/usr/lib64/nagios/plugins/check_nrpe -H 192.168.56.13
/usr/lib64/nagios/plugins/check_nrpe -H 192.168.56.12
/usr/lib64/nagios/plugins/check_nrpe -H 192.168.56.11
```

A version or PONG-style reply means that VM's NRPE agent is up. Connection refused means the agent is not running or port 5666 is closed.

Then test CPU and RAM on each host, for example `db01`:

```bash
/usr/lib64/nagios/plugins/check_nrpe -H 192.168.56.15 -c check_load
/usr/lib64/nagios/plugins/check_nrpe -H 192.168.56.15 -c check_ram
```

Repeat with `.14`, `.13`, `.12`, and `.11`. `NRPE: Command 'check_load' not defined` means that VM is missing section 3 of its command file.

In the Nagios UI:

- **Hosts** (Current Status → Hosts) shows only ping. That is expected. A host is UP or DOWN. CPU and RAM are not host checks.
- **Services** (Current Status → Services) shows Ping Check, CPU Load, and RAM for each VM.

If CPU/RAM say UNKNOWN or `(No output returned from plugin)`, install `nagios-plugins-nrpe` and run `sudo systemctl restart nagios`. First checks can take up to 5 minutes, or click the service and **Re-schedule the next check**.
