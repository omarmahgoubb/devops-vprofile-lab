# 10 — Path 2: Jenkins deploys with kubectl

Kaniko still pushes `acrvprofilel8.azurecr.io/vprofile-app:<git sha>` to ACR. The Git tag stage is gone. Jenkins runs `kubectl set image` on `deployment/app01`. Argo CD must not be watching, or self-heal puts the git image back.

## 1. Let the Jenkins pod update the app

On the master:

```bash
kubectl apply -f - <<'EOF'
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: jenkins-deploy
  namespace: vprofile
rules:
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["get", "list", "watch", "update", "patch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: jenkins-deploy
  namespace: vprofile
subjects:
  - kind: ServiceAccount
    name: default
    namespace: jenkins
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: jenkins-deploy
EOF
```

## 2. Remove the Argo app and keep the running pods

```bash
kubectl -n argocd patch application vprofile --type merge -p '{"metadata":{"finalizers":null}}'
kubectl -n argocd delete application vprofile
kubectl -n vprofile get pods
```

Clearing the finalizer keeps `app01`, `db01`, `mc01`, and `rmq01`. A normal delete would remove them.

The Jenkinsfile push comes after this delete. Commit `7a7660d` is on `main`. The webhook should build it. Kaniko pushes the image, then `kubectl set image` rolls `app01`. There is no second tag commit.

## Proof

Jenkins succeeded for `7a7660d6b3f0e38270c56ca68917135f8c9bce47`. New pod `app01-6dcd6cf7d7-87jnc` became `Running`. The previous pod `app01-db7487bd7-442bl` showed `Error` while it was terminating; that is the old container exiting. `http://40.87.97.146:30080/login` returned 200 with `welcome omar`.

Commit `982ad1a` redesigned that same page: dark background, green bar, rounded card, no yellow logo. The webhook built it, `kubectl` rolled a new `app01` pod, and the live page showed that design.
