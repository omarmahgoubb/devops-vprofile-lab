# Class Dockerfiles (as shown)

## App (Java / Tomcat)

```dockerfile
FROM tomcat:8-jre11
RUN rm -rf /usr/local/tomcat/webapps/*
COPY vprofile-v2.war /usr/local/tomcat/webapps/ROOT.war
EXPOSE 8080
WORKDIR /usr/local/tomcat/
CMD ["catalina.sh", "run"]
```

If the WAR is still under `target/`, use `COPY target/vprofile-v2.war ...` instead.

## DB (MySQL)

```dockerfile
FROM mysql:5.7.25
ENV MYSQL_ROOT_PASSWORD="admin123"
ENV MYSQL_DATABASE="accounts"
ADD db_backup.sql docker-entrypoint-initdb.d/db_backup.sql
```

## Nginx

```dockerfile
FROM nginx
RUN rm -rf /etc/nginx/conf.d/default.conf
COPY nginvproapp.conf /etc/nginx/conf.d/vproapp.conf
```
