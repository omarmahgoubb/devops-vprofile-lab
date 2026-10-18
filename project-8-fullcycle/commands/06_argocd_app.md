# 06 — Private repo connected. Application not created yet

The repo `https://github.com/omarmahgoubb/vprofile` is connected in Argo CD over HTTPS. The token is not stored in this repo. The Application is the next click.

## Repository

In the UI: **Settings → Repositories → Connect Repo**.

| Field | Value |
|---|---|
| Connection method | HTTPS |
| Repository URL | `https://github.com/omarmahgoubb/vprofile` |
| Username | `omarmahgoubb` |
| Password | GitHub personal access token with read access to that repo |

A successful connection says the repository is connected. Then **New App**.

## Application

The UI Create button stayed disabled while `destination.server` and `destination.namespace` were empty. `Prune=false` is not a sync option. Paste this with **Edit as YAML**:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: vprofile
spec:
  project: default
  source:
    repoURL: https://github.com/omarmahgoubb/vprofile
    targetRevision: main
    path: k8s
  destination:
    server: https://kubernetes.default.svc
    namespace: vprofile
  syncPolicy:
    syncOptions:
      - CreateNamespace=true
```

## Form fields (same result)

| Field | Value |
|---|---|
| Application name | `vprofile` |
| Project | `default` |
| Sync policy | Manual |
| Repository URL | `https://github.com/omarmahgoubb/vprofile` |
| Revision | `main` |
| Path | `k8s` |
| Cluster URL | `https://kubernetes.default.svc` |
| Namespace | `vprofile` |

`k8s/app.yaml` holds the Namespace, Deployment `app01`, and Service NodePort **30080**. The image is still `omarrmahgoub/vprofile-app:v1`. `k8s/data.yaml` adds MariaDB `db01`, Memcached `mc01`, and RabbitMQ `rmq01` with the hostnames from `application.properties`. Jenkins rewrites only the app image line in `k8s/app.yaml`.

Created from the YAML above. First sync at 2026-10-18 03:34 UTC: **Healthy / Synced**. Resources: Namespace `vprofile`, Service `app01` NodePort 30080, Deployment `app01`. Image in Git is still `omarrmahgoub/vprofile-app:v1`. Prune was off.

`k8s/data.yaml` was pushed as `1879645` and synced. `db01`, `mc01`, `rmq01`, and Job `db01-grant` came up. Login at `http://40.87.97.146:30080` with `admin_vp` / `admin_vp` worked without restarting `app01`.
