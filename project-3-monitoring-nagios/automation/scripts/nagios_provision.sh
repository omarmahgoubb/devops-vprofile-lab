#!/bin/bash

# yum update -y
# dnf update -y

echo "Installing Nagios Core, plugins, NRPE plugin, and Apache..."
yum install -y epel-release
yum install -y nagios nagios-plugins-all nrpe nagios-plugins-nrpe httpd --skip-broken

echo "Enabling and starting httpd and nagios..."
systemctl enable httpd
systemctl start httpd
systemctl enable nagios
systemctl start nagios
systemctl start firewalld.service

echo "Configuring firewall..."
firewall-cmd --add-service=http --permanent
firewall-cmd --add-port=5666/tcp --permanent
firewall-cmd --reload

echo "Setting nagiosadmin web password (admin123)..."
htpasswd -b -c /etc/nagios/passwd nagiosadmin admin123

echo "Writing monitored hosts..."
cat >/etc/nagios/objects/clients.cfg <<'EOL'
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
EOL

echo "Writing ping, CPU, and RAM services..."
cat >/etc/nagios/objects/services.cfg <<'EOL'
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
EOL

if ! grep -q 'command_name[[:space:]]*check_nrpe' /etc/nagios/objects/commands.cfg; then
  cat >>/etc/nagios/objects/commands.cfg <<'EOL'
define command {
    command_name    check_nrpe
    command_line    $USER1$/check_nrpe -H $HOSTADDRESS$ -c $ARG1$
}
EOL
fi

grep -q 'objects/clients.cfg' /etc/nagios/nagios.cfg || echo "cfg_file=/etc/nagios/objects/clients.cfg" >> /etc/nagios/nagios.cfg
grep -q 'objects/services.cfg' /etc/nagios/nagios.cfg || echo "cfg_file=/etc/nagios/objects/services.cfg" >> /etc/nagios/nagios.cfg

echo "Validating Nagios configuration..."
nagios -v /etc/nagios/nagios.cfg
systemctl restart nagios

echo "Nagios services and commands configuration updated successfully."
echo "Web UI: http://192.168.56.10/nagios  (nagiosadmin / admin123)"
echo "Open Current Status -> Services for CPU Load and RAM (Hosts shows ping only)."
