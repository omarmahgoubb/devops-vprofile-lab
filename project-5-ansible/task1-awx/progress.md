# Task 1 progress log

**Status: Task 1 complete.** AWX dashboard opened at http://127.0.0.1:8088 (`admin`).

| Field | Value |
|---|---|
| VM | `awx01` |
| OS | Ubuntu 22.04 (`ubuntu/jammy64`) |
| RAM | 8192 MB |
| IP | `192.168.56.20` |
| AWX URL (from Windows) | http://127.0.0.1:8088 |
| User | `admin` |

Password is **not** stored here. Gotcha: operator `2.19.0` needed `kube-rbac-proxy` pointed at `quay.io/brancz/kube-rbac-proxy:v0.15.0` (GCR image is gone).

The Dashboard cards (1 host / 1 inventory / 1 project) are AWX **demo defaults**, not the vprofile VMs. Adding those is Task 2.

Keep the port-forward running when you want the UI:

```bash
kubectl port-forward --address 0.0.0.0 svc/awx-ubuntu-service 8080:80 -n ansible-awx
```
