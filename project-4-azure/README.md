# DevOps VProfile Lab — Azure (Lecture 4)

Same Java app as the on-prem Vagrant labs. The session was shown on AWS. This repo is the **Azure** version.

On-prem we had five VMs, including Nginx. For these Azure tasks the instructor dropped Nginx. You open Tomcat on the app VM.

**Task 1 is done** (we deleted resource group `vprofile` after it worked, to stop charges). Recreate with [task1-manual/deploy/vm.json](task1-manual/deploy/vm.json). App login: `admin_vp` / `admin_vp`. Log: [task1-manual/progress.md](task1-manual/progress.md).

## Tasks

| Task | What we do |
|---|---|
| **[task1-manual/](task1-manual/)** | **Done.** 4 VMs in `vprofile` (East US). Portal + [deploy/vm.json](task1-manual/deploy/vm.json). Commands in `task1-manual/commands/`. |
| **task2-automated/** | Same 4 VMs, but the Lecture 2 bash scripts run as Azure **Custom data** (AWS called this User data). |
| **task3-azure-services/** | Replace self-hosted MariaDB / Memcached / RabbitMQ / public IP with Azure managed services. |

Task 1 works. Task 2 and Task 3 are next.

## Stack (Task 1 and Task 2)

| VM name | Role | Port | OS |
|---|---|---|---|
| `db01` | MariaDB | 3306 | CentOS Stream 9 |
| `mc01` | Memcached | 11211/tcp, 11111/udp | CentOS Stream 9 |
| `rmq01` | RabbitMQ | 5672 | CentOS Stream 9 |
| `app01` | Tomcat + vprofile WAR | 8080 (public) | CentOS Stream 9 |

Bring-up order: **db01 → mc01 → rmq01 → app01**.

Browser → `app01:8080` → `db01` / `mc01` / `rmq01` on the private VNet.

## AWS word → Azure word

| AWS (session) | Azure (what we click) |
|---|---|
| EC2 instance | Virtual machine |
| AMI / Amazon Linux or CentOS | Image (CentOS Stream 9) |
| t2.micro / small type | Size `Standard_B1s` (app: `Standard_B2s`) |
| Default VPC | Default VNet (leave as-is) |
| Security group | Network security group (NSG) |
| User data | Custom data (Advanced) |
| Public IPv4 | Public IP |
| SSH to the instance | SSH to the public IP |

Full mapping: [docs/aws-to-azure.md](docs/aws-to-azure.md). Ports and flow: [docs/architecture.md](docs/architecture.md).

## Image (do not change this)

**CentOS Stream 9** — same family as the Lecture 2 Vagrant box (`eurolinux-vagrant/centos-stream-9`).

In the portal search box: `CentOS Stream 9`.

Do **not** pick Ubuntu (that is `apt`, all commands change). Do **not** pick Rocky or Alma for Task 1 (`rmq01` installs `centos-release-rabbitmq-38`, which is a CentOS package).

## Why manual first?

Same reason as Project 1. Doing it by hand once makes the Custom-data scripts in Task 2 obvious.

> Lab passwords: app `admin_vp` / `admin_vp`, MariaDB `admin` / `admin123`, RabbitMQ `test` / `test`. Learning only. Do not reuse them. SSH is `azureuser` (password not in git).
