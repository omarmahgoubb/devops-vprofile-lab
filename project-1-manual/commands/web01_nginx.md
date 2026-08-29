# web01 — Nginx reverse proxy setup

SSH from the Windows host into the web01 VM:

```bash
vagrant ssh web01
```

Update the Ubuntu package lists:

```bash
sudo apt update
```

Install Nginx (the reverse proxy / load balancer in front of Tomcat):

```bash
sudo apt install nginx -y
```

Create a new Nginx site config for the vprofile app:

```bash
sudo vim /etc/nginx/sites-available/vproapp
```

In vim: press `i`, paste the config below, then press `Esc` and type `:wq`.

This sends all HTTP traffic on port 80 to Tomcat on `app01:8080`:

```nginx
upstream vproapp {
server app01:8080;
}
server {
listen 80;
location / {
proxy_pass http://vproapp;
}
}
```

Remove the default Nginx site so it does not conflict with yours:

```bash
sudo rm -rf /etc/nginx/sites-enabled/default
```

Enable the vproapp site by linking it into `sites-enabled`:

```bash
sudo ln -s /etc/nginx/sites-available/vproapp /etc/nginx/sites-enabled/vproapp
```

Restart Nginx so the new reverse-proxy config is active:

```bash
sudo systemctl restart nginx
```

If restart fails with `host not found in upstream "app01:8080"`, `web01` cannot resolve `app01`. From the Windows host in this folder run `vagrant hostmanager`, then retry `sudo systemctl restart nginx`. After that, open **http://192.168.56.11**. A Tomcat 404 at `/` means the app failed to start on `app01` (usually Java 17). Point Tomcat at `/usr/lib/jvm/jre-11-openjdk` and restart it.
