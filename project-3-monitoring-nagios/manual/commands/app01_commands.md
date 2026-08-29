# app01 — Tomcat / Java app + NRPE agent

IP: `192.168.56.12` · CentOS Stream 9

```bash
vagrant ssh app01
```

---

## 1. Tomcat and the vprofile WAR (same as Lecture 2, with Java 11)

Optional and slow. Skip if you want to save time:

```bash
sudo dnf update -y
```

Install the EPEL repo so extra packages become available:

```bash
sudo dnf install epel-release -y
```

Install Java 11 (runtime + compiler), Git, Maven, and wget:

```bash
sudo dnf install java-11-openjdk java-11-openjdk-devel git maven wget -y
```

Go to `/tmp` to download Tomcat:

```bash
cd /tmp/
```

Download Apache Tomcat 9.0.75:

```bash
wget https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.75/bin/apache-tomcat-9.0.75.tar.gz
```

Extract the Tomcat archive:

```bash
tar xzvf apache-tomcat-9.0.75.tar.gz
```

Enter the extracted Tomcat folder:

```bash
cd apache-tomcat-9.0.75
```

Create a `tomcat` system user with home `/usr/local/tomcat` and no login shell:

```bash
sudo useradd tomcat -md /usr/local/tomcat -s /sbin/nologin
```

Copy all Tomcat files into `/usr/local/tomcat`:

```bash
sudo cp * /usr/local/tomcat/ -r
```

Give the `tomcat` user ownership of the Tomcat directory:

```bash
sudo chown -R tomcat:tomcat /usr/local/tomcat
```

Create a systemd unit so Tomcat can be managed with `systemctl`:

```bash
sudo vim /etc/systemd/system/tomcat.service
```

In vim: press `i`, paste the service file below, then press `Esc` and type `:wq`.

Point `JRE_HOME` and `JAVA_HOME` at **Java 11**, not `/usr/lib/jvm/jre`. Maven often installs Java 17 as well, and `/usr/lib/jvm/jre` then follows Java 17. This old Spring app fails on Java 17, Tomcat stays up, and the browser shows a Tomcat 404.

```ini
[Unit]
Description=Tomcat
After=network.target
[Service]
User=tomcat
WorkingDirectory=/usr/local/tomcat
Environment=JRE_HOME=/usr/lib/jvm/jre-11-openjdk
Environment=JAVA_HOME=/usr/lib/jvm/jre-11-openjdk
Environment=CATALINA_HOME=/usr/local/tomcat
Environment=CATALINE_BASE=/usr/local/tomcat
ExecStart=/usr/local/tomcat/bin/catalina.sh run
ExecStop=/usr/local/tomcat/bin/shutdown.sh
SyslogIdentifier=tomcat-%i
[Install]
WantedBy=multi-user.target
```

Reload systemd so it sees the new Tomcat service:

```bash
sudo systemctl daemon-reload
```

Start Tomcat now:

```bash
sudo systemctl start tomcat
```

Enable Tomcat to start automatically on boot:

```bash
sudo systemctl enable tomcat
```

Start the firewall service:

```bash
sudo systemctl start firewalld
```

Enable the firewall to start automatically on boot:

```bash
sudo systemctl enable firewalld
```

Show which firewall zone is active:

```bash
sudo firewall-cmd --get-active-zones
```

Allow incoming Tomcat HTTP traffic (TCP 8080) permanently:

```bash
sudo firewall-cmd --zone=public --add-port=8080/tcp --permanent
```

Reload the firewall so the 8080 rule becomes active now:

```bash
sudo firewall-cmd --reload
```

Go to `/tmp` and clone the vprofile application source:

```bash
cd
cd /tmp
git clone -b main https://github.com/hkhcoder/vprofile-project.git
```

Enter the project folder and build the WAR with Maven. `-DskipTests` avoids a JaCoCo failure on newer class-file versions:

```bash
cd vprofile-project
mvn install -DskipTests
```

Stop Tomcat before deploying the WAR:

```bash
sudo systemctl stop tomcat
```

Remove the default Tomcat ROOT app so yours can take its place:

```bash
sudo rm -rf /usr/local/tomcat/webapps/ROOT
```

Copy the built WAR to Tomcat as `ROOT.war` (it will deploy at `/`):

```bash
sudo cp target/vprofile-v2.war /usr/local/tomcat/webapps/ROOT.war
```

Give the `tomcat` user ownership of the webapps folder:

```bash
sudo chown tomcat:tomcat /usr/local/tomcat/webapps -R
```

Start Tomcat so it deploys the WAR:

```bash
sudo systemctl start tomcat
```

Wait about 20 seconds, then confirm Tomcat is using Java 11:

```bash
sudo systemctl status tomcat
```

Do **not** run a pinned `dnf remove java-17-openjdk-...-<old-version>`. Those RPM versions change and `dnf` will find no match. Java 17 can stay installed as long as Tomcat points at `jre-11-openjdk`.

If the browser still shows a Tomcat 404 at `/`, Java 17 is still selected. Recheck `JRE_HOME` in `/etc/systemd/system/tomcat.service`.

---

## 2. NRPE agent (new in this lecture)

```bash
sudo dnf install -y nrpe nagios-plugins-all --skip-broken
```

Allow the Nagios server to connect:

```bash
echo "allowed_hosts=127.0.0.1,192.168.56.10" | sudo tee -a /etc/nagios/nrpe.cfg
```

```bash
sudo systemctl enable nrpe
sudo systemctl start nrpe
```

```bash
sudo firewall-cmd --add-port=5666/tcp --permanent
sudo firewall-cmd --reload
```

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

Register both checks in NRPE. These VMs have about **one CPU and 600–800 MB RAM**, so load thresholds are low:

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
