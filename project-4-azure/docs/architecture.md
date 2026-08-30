# Architecture — Azure Task 1

Four Linux VMs in resource group **`vprofile`** (East US), one VNet **`vnet-eastus-1`** / **`snet-eastus-1`** (`172.16.0.0/24`). No Nginx.

**Hosts (as built)**

| Host | Private IP | Public IP | Role |
|---|---|---|---|
| `db01` | `172.16.0.4` | `172.190.151.113` | MariaDB TCP 3306 |
| `mc01` | `172.16.0.5` | `13.92.29.156` | Memcached TCP 11211, UDP 11111 |
| `rmq01` | `172.16.0.6` | `20.85.239.154` | RabbitMQ TCP 5672 |
| `app01` | `172.16.0.7` | `20.85.229.239` | Tomcat TCP 8080 |

**Flow**

Client → [http://20.85.229.239:8080](http://20.85.229.239:8080) → Tomcat → cache (`mc01:11211`) and DB (`db01:3306`); async work via `rmq01:5672`.

Azure DNS in the VNet resolves the short names `db01` / `mc01` / `rmq01`, so the Java app keeps the same hostnames as Vagrant hostmanager.

**NSG**

- All VMs: inbound SSH 22 (lab).
- **Change we made after Tomcat was up:** on **`app01-nsg`** add inbound rule `allow-8080`, TCP **8080**, priority 1010, source Any. Without this, `http://<app01-public-ip>:8080` times out even if Tomcat is running.
- 3306 / 11211 / 5672 are not opened to the internet. VNet-to-VNet is already allowed.

**Bring-up order**

MariaDB → Memcached → RabbitMQ → Tomcat.
