# app01 — Tomcat / Java app setup

SSH (password, user `azureuser`):

```bash
ssh azureuser@<app01-public-ip>
```

There is no Nginx in this lab. When Tomcat is up, open `http://<app01-public-ip>:8080` and add NSG inbound TCP 8080 on this VM.

Update all installed packages on CentOS Stream 9 to the latest versions:

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

Point `JRE_HOME` and `JAVA_HOME` at **Java 11**, not `/usr/lib/jvm/jre`. Maven often installs Java 17 as well, and `/usr/lib/jvm/jre` then follows Java 17. This old Spring app fails on Java 17 (`InaccessibleObjectException`), Tomcat stays up, and the browser shows a Tomcat 404.

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

Enter the project folder and build the WAR with Maven:

```bash
cd vprofile-project
mvn install
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
sudo chown tomcat.tomcat /usr/local/tomcat/webapps -R
```

Start Tomcat so it deploys the WAR:

```bash
sudo systemctl start tomcat
```

If the service file was created earlier with `/usr/lib/jvm/jre` (that symlink often points at Java 17), retarget Tomcat to Java 11 and restart. Do not remove Java 17 by a pinned RPM version; that version changes and `dnf` will find no match.

```bash
sudo sed -i 's|JRE_HOME=/usr/lib/jvm/jre$|JRE_HOME=/usr/lib/jvm/jre-11-openjdk|' /etc/systemd/system/tomcat.service
sudo sed -i 's|JAVA_HOME=/usr/lib/jvm/jre$|JAVA_HOME=/usr/lib/jvm/jre-11-openjdk|' /etc/systemd/system/tomcat.service
sudo systemctl daemon-reload
sudo systemctl restart tomcat
```

Wait about 20 seconds, then confirm Tomcat is using Java 11:

```bash
sudo systemctl status tomcat
```

If the browser still shows a Tomcat 404 at `/`, Java 17 is still selected. Recheck `JRE_HOME` in `/etc/systemd/system/tomcat.service`.

Then add the Azure NSG rule (this is **not** the same as `firewalld` above). Portal: resource group `vprofile` → NSG **`app01-nsg`** → Inbound security rules → Add:

| Field | Value |
|---|---|
| Name | `allow-8080` |
| Priority | `1010` |
| Source | Any |
| Destination port | `8080` |
| Protocol | TCP |
| Action | Allow |

Or:

```powershell
az network nsg rule create --resource-group vprofile --nsg-name app01-nsg --name allow-8080 --priority 1010 --access Allow --protocol Tcp --direction Inbound --source-address-prefixes '*' --destination-port-ranges 8080
```

Then open `http://<app01-public-ip>:8080` (lab login `admin_vp` / `admin_vp`).
