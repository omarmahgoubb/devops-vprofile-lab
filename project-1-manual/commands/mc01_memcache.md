# mc01 — Memcached setup

SSH from the Windows host into the mc01 VM:

```bash
vagrant ssh mc01
```

Update all installed packages on CentOS Stream 9 to the latest versions:

```bash
sudo dnf update -y
```

Install the EPEL repo so extra packages become available:

```bash
sudo dnf install epel-release -y
```

Install the Memcached caching service:

```bash
sudo dnf install memcached -y
```

Enable Memcached to start automatically on boot:

```bash
sudo systemctl enable memcached
```

Start Memcached now:

```bash
sudo systemctl start memcached
```

Change the listen address from localhost (`127.0.0.1`) to all interfaces (`0.0.0.0`) so other VMs can reach the cache:

```bash
sudo sed -i 's/127.0.0.1/0.0.0.0/g' /etc/sysconfig/memcached
```

Restart Memcached so it listens on all interfaces:

```bash
sudo systemctl restart memcached
```

Start the firewall service:

```bash
sudo systemctl start firewalld
```

Enable the firewall to start automatically on boot:

```bash
sudo systemctl enable firewalld
```

Allow Memcached TCP traffic on port 11211 (runtime rule):

```bash
sudo firewall-cmd --add-port=11211/tcp
```

Save the current runtime firewall rules so they survive a reboot:

```bash
sudo firewall-cmd --runtime-to-permanent
```

Allow Memcached UDP traffic on port 11111 (runtime rule):

```bash
sudo firewall-cmd --add-port=11111/udp
```

Save the UDP rule permanently as well:

```bash
sudo firewall-cmd --runtime-to-permanent
```

Start a Memcached daemon listening on TCP 11211 and UDP 11111 as the `memcached` user:

```bash
sudo memcached -p 11211 -U 11111 -u memcached -d
```
