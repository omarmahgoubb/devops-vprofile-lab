# Login fix — GRANT + skip-ssl

The form user is `admin_vp` / `admin_vp`. JDBC is `admin` / `admin123`. Official MySQL does not create `admin`. Connector/J 8 vs `mysql:5.7.25` fails TLS (`SSLHandshakeException`). The page then says the password is invalid.

```bash
cd ~/vprofile-docker/compose

docker exec db01 mysql -uroot -padmin123 -e "GRANT ALL ON accounts.* TO 'admin'@'%' IDENTIFIED BY 'admin123'; FLUSH PRIVILEGES;"

docker exec db01 mysql -uadmin -padmin123 accounts -e "SELECT username FROM user;"
```

You must see `admin_vp`.

If `docker-compose.yml` already has `command: --skip-ssl`, recreate and restart:

```bash
docker compose up -d db01
docker exec db01 mysqladmin -uroot -padmin123 ping
docker compose restart app01
```

If the YAML does **not** have that line yet (first lab run), this run only:

```bash
docker exec db01 bash -c 'printf "[mysqld]\nskip-ssl\n" > /etc/mysql/conf.d/skip-ssl.cnf'
docker compose restart db01
docker exec db01 mysqladmin -uroot -padmin123 ping
docker compose restart app01
```

Wait ~25 seconds, then:

```bash
docker compose logs --tail=80 app01 | grep -E 'SSLHandshake|Server startup|ERROR'
```

You want `Server startup in … ms` and no `SSLHandshakeException`. Log4j2 / Hibernate `ERROR` lines are normal.

Laptop: **http://192.168.56.123** — `admin_vp` / `admin_vp`.

If it fails again:

```bash
docker compose logs --tail=50 app01 | grep -E 'SSLHandshake|Communications|Access denied|ERROR'
docker exec app01 bash -c "grep jdbc /usr/local/tomcat/webapps/ROOT/WEB-INF/classes/application.properties"
```
