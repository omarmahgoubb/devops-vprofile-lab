# mc01 — Memcached setup

SSH (password, user `azureuser`):

```bash
ssh azureuser@<mc01-public-ip>
```

Add swap first (`B1s` is 1 GiB — skip the full `dnf update` on this VM):

```bash
sudo dd if=/dev/zero of=/swapfile bs=1M count=2048 status=progress
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
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
