# Compose login — extra steps (after `up -d`)

The login page can load (`WELCOME!`) while `/login?error` says the password is invalid. That message is often a **DB connection** problem, not a wrong password.

App user (the web form): `admin_vp` / `admin_vp`  
JDBC user (Java → MySQL): `admin` / `admin123`  
MySQL root: `root` / `admin123`

On VMs we created `admin` with `GRANT`. The official `mysql:5.7.25` image only creates `root` (and the `accounts` DB from the dump). Connector/J **8** inside the WAR also tries TLS against that old MySQL image; the handshake fails.

Do both steps on the **VM**, in `~/vprofile-docker/compose`.

## 1. Create the JDBC user

```bash
docker exec db01 mysql -uroot -padmin123 -e "GRANT ALL ON accounts.* TO 'admin'@'%' IDENTIFIED BY 'admin123'; FLUSH PRIVILEGES;"
```

Check the dump actually loaded:

```bash
docker exec db01 mysql -uadmin -padmin123 accounts -e "SELECT username FROM user;"
```

You must see `admin_vp`.

## 2. Turn off MySQL SSL (5.7.25 vs Connector/J 8)

`application.properties` in the WAR looks like this (no `useSSL=false`):

```text
jdbc.url=jdbc:mysql://db01:3306/accounts?useUnicode=true&characterEncoding=UTF-8&zeroDateTimeBehavior=convertToNull
jdbc.username=admin
jdbc.password=admin123
```

Without this step, `app01` logs `SSLHandshakeException` / `Communications link failure` and login always fails.

This run only (lost if you recreate the container):

```bash
docker exec db01 bash -c 'printf "[mysqld]\nskip-ssl\n" > /etc/mysql/conf.d/skip-ssl.cnf'
docker compose restart db01
docker exec db01 mysqladmin -uroot -padmin123 ping
```

Wait until `mysqld is alive`, then:

```bash
docker compose restart app01
```

Wait ~25 seconds (WAR deploy). Confirm Tomcat is up and there is **no** handshake error:

```bash
docker compose logs --tail=80 app01 | grep -E 'SSLHandshake|Server startup|ERROR'
```

You want `Server startup in … ms`. These two `ERROR` lines are normal for this WAR (Log4j2, Hibernate). They are not the login bug.

Then from the laptop: **http://192.168.56.123** — `admin_vp` / `admin_vp`.

## Keep it after the next `compose down`

[compose/docker-compose.yml](../compose/docker-compose.yml) already has `command: --skip-ssl` under `db01`. Recreate picks it up (no `printf` next time):

```bash
docker compose up -d db01
docker compose restart app01
```

Optional on a **new** volume only (env is ignored if `dbdata` already exists):

```yaml
    environment:
      MYSQL_ROOT_PASSWORD: admin123
      MYSQL_DATABASE: accounts
      MYSQL_USER: admin
      MYSQL_PASSWORD: admin123
```

If the volume already exists, keep using the `GRANT` from step 1.

If you need a truly fresh DB (re-run init + create `admin` from env):

```bash
docker compose down
docker volume rm compose_dbdata
docker compose up -d
```

Then still confirm `mysqld is alive` and `SELECT username FROM user` before you test login.

## If login fails again

```bash
docker compose logs --tail=50 app01 | grep -E 'SSLHandshake|Communications|Access denied|ERROR'
docker exec app01 bash -c "grep jdbc /usr/local/tomcat/webapps/ROOT/WEB-INF/classes/application.properties"
```

`Access denied` → step 1. `SSLHandshake` / `Communications link failure` → step 2 (or add `useSSL=false` on `jdbc.url` if `skip-ssl` is not enough).
