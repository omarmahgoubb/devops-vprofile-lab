# Session was AWS — we operate on Azure

The instructor demonstrated on AWS. Every step has an Azure equivalent.

| What he did | AWS name | Azure name | What we do |
|---|---|---|---|
| Create 4 small Linux machines | EC2 | Virtual machines | Create `db01`, `mc01`, `rmq01`, `app01` |
| CentOS-like OS | AMI | Image | **CentOS Stream 9** |
| Small machine | Instance type | Size | `Standard_B1s`; `app01` use `Standard_B2s` (Maven needs RAM) |
| Leave network default | Default VPC | Default VNet | Do not draw a custom VNet |
| Security group, no extra rules at create | Security group | NSG | Allow SSH when the wizard asks; add 8080 later on `app01` |
| Copy public IP and log in | Elastic / public IP | Public IP | `ssh -i key.pem azureuser@<public-ip>` |
| Script on first boot | User data (Advanced details) | Custom data | Task 2 only |

Task 3 mapping (later, not Task 1):

| On-prem / Task 1 | AWS (his notes) | Azure |
|---|---|---|
| MariaDB VM | RDS | Azure Database for MySQL |
| Memcached VM | ElastiCache | Azure Cache for Redis |
| RabbitMQ VM | SQS | Service Bus (or keep a small RMQ VM) |
| Tomcat VM | EC2 | Linux VM |
| Nginx | ELB | Not used in these tasks |
| App files | S3 | Blob Storage |
