# 05 — Argo CD installed

UI is open at **http://40.87.97.146:30081**, Argo CD **v3.5.5**, user `admin`. The Applications page is empty. The admin password is not stored in this repo.

Both nodes are Ready. Argo CD is the deploy half: it watches Git and applies YAML. It does not build the image. Jenkins comes after this. The commands below are what produced this UI.

Run on the master. Do not set the server container args to only `--insecure`. That crashed Argo CD 3.5 in Lecture 7 (exit 127). `server.insecure` belongs in the ConfigMap, then the server is restarted.

The ApplicationSet CRD can fail with an annotation longer than 256 KB. One Application does not need it. Continue if that is the only error.

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl -n argocd get pods
```

When the `argocd-server` pod exists:

```bash
kubectl -n argocd patch configmap argocd-cmd-params-cm --type merge -p '{"data":{"server.insecure":"true"}}'
kubectl -n argocd patch svc argocd-server -p '{"spec":{"type":"NodePort","ports":[{"name":"http","port":80,"targetPort":8080,"nodePort":30081}]}}'
kubectl -n argocd rollout restart deploy/argocd-server
kubectl -n argocd rollout status deploy/argocd-server
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```

UI: `http://40.87.97.146:30081`. User `admin`. Do not commit the password. The worker public IP `23.100.22.38:30081` is the same service.
