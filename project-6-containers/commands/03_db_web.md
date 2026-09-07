# DB image, web image, official pulls

Free port 8080 before Compose (the solo test container is still using it). The **image** stays:

```bash
docker stop vprofile-app
docker rm vprofile-app
```

## MySQL

```bash
mkdir -p ~/vprofile-docker/db
cp ~/vprofile-docker/app/vprofile-project/src/main/resources/db_backup.sql ~/vprofile-docker/db/
cd ~/vprofile-docker/db
```

`vim Dockerfile`:

```dockerfile
FROM mysql:5.7.25
ENV MYSQL_ROOT_PASSWORD="admin123"
ENV MYSQL_DATABASE="accounts"
ADD db_backup.sql docker-entrypoint-initdb.d/db_backup.sql
```

```bash
docker build -t omarrmahgoub/vprofile-db:v1 .
```

The `MYSQL_ROOT_PASSWORD` warning is normal for this lab.

## Nginx

```bash
mkdir -p ~/vprofile-docker/web
cd ~/vprofile-docker/web
```

`vim nginvproapp.conf` — upstream name must be the Compose service `app01`:

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

`vim Dockerfile`:

```dockerfile
FROM nginx
RUN rm -rf /etc/nginx/conf.d/default.conf
COPY nginvproapp.conf /etc/nginx/conf.d/vproapp.conf
```

```bash
docker build -t omarrmahgoub/vprofile-web:v1 .
```

## Official (no Dockerfile)

```bash
docker pull memcached
docker pull rabbitmq
```

`rabbitmq` (not `rabbitmq:management`) has no UI on 15672. The app needs **5672**.
