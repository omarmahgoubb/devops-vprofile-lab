# Step 1 — Select the right image

Ask: is there an official image for this role, at a version we can pin?

| Role | Ready image? | What we use |
|---|---|---|
| vprofile app | **No** | `tomcat:8-jre11` + our `Dockerfile` + WAR |
| Database | Yes | `mysql:5.7.25` + SQL init Dockerfile. Create JDBC user `admin` yourself; turn off SSL for Connector/J 8 ([compose-login.md](compose-login.md)). |
| Nginx | Yes | `nginx` + our site conf Dockerfile |
| Memcached | Yes | `memcached` (latest for the lab) |
| RabbitMQ | Yes | `rabbitmq` (latest for the lab) |

On-prem we used **Tomcat 9.0.75**. This lecture uses **`tomcat:8-jre11`**. Stay on the class image.

Pull when NAT/DNS works:

```bash
docker pull tomcat:8-jre11
docker pull mysql:5.7.25
docker pull nginx
docker pull memcached
docker pull rabbitmq
```
