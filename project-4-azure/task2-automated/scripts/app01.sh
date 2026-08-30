#!/bin/bash
# app01 — Tomcat + vprofile WAR (Azure Custom data, runs once as root)
exec > /var/log/vprofile-customdata.log 2>&1
set -eux

sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config.d/01-localconfig.conf || true
printf 'PasswordAuthentication yes\n' > /etc/ssh/sshd_config.d/99-password.conf
systemctl restart sshd || true

if [ ! -f /swapfile ]; then
  dd if=/dev/zero of=/swapfile bs=1M count=2048
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

# B2s can take a full update; skip it so first boot finishes sooner (same as Lecture 2).
dnf install epel-release -y
dnf install java-11-openjdk java-11-openjdk-devel git maven wget -y

cd /tmp
wget -q https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.75/bin/apache-tomcat-9.0.75.tar.gz
tar xzvf apache-tomcat-9.0.75.tar.gz
cd apache-tomcat-9.0.75
id tomcat &>/dev/null || useradd tomcat -md /usr/local/tomcat -s /sbin/nologin
cp -r * /usr/local/tomcat/
chown -R tomcat:tomcat /usr/local/tomcat

cat > /etc/systemd/system/tomcat.service <<'EOF'
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
EOF

systemctl daemon-reload
systemctl enable --now tomcat

systemctl start firewalld
systemctl enable firewalld
firewall-cmd --zone=public --add-port=8080/tcp --permanent
firewall-cmd --reload

cd /tmp
if [ ! -d vprofile-project ]; then
  git clone -b main https://github.com/hkhcoder/vprofile-project.git
fi
cd /tmp/vprofile-project
# skipTests: JaCoCo fails on newer class-file versions (Lecture 2)
mvn install -DskipTests

systemctl stop tomcat
rm -rf /usr/local/tomcat/webapps/ROOT
cp /tmp/vprofile-project/target/vprofile-v2.war /usr/local/tomcat/webapps/ROOT.war
chown -R tomcat:tomcat /usr/local/tomcat/webapps
systemctl start tomcat

echo "app01 custom data done"
