# 08 — Kaniko pipeline

Credentials `acr-vprofile` and `github-vprofile` are saved. The controller pod is not replaced. Replacing it would wipe `emptyDir` and those credentials.

Kaniko builds the `Dockerfile` and pushes to ACR. Docker is not installed. The Jenkins pod's default service account is allowed to create the build pod. The ACR pull secret is copied into namespace `jenkins` because a pod cannot mount a secret from `vprofile`.

Test Connection first returned 403: `system:serviceaccount:jenkins:default` cannot list pods in namespace `jenkins`. The Role below is the fix. The Jenkins pod is not replaced.

The first build pod scheduled onto `vm-vprofile-worker` and then failed the Kaniko volume: `secret "acr-pull" not found` in namespace `jenkins`. The secret was only in `vprofile`. The Python copy created `acr-pull` in `jenkins` (`kubernetes.io/dockerconfigjson`). The password was not printed. Pod `vprofile-build-1-d8c9p-vm6v6-2jd87` then became `2/2 Running`: Kaniko image pulled in about 8 seconds, inbound-agent in about 10 seconds. The agent still stayed offline. Its log said port `50000` on `jenkins.jenkins.svc.cluster.local` was not reachable. The Service only published `8080`. Adding the `jnlp` port `50000` on Service `jenkins` did not replace the controller pod. The agent then logged `Agent discovery successful` and `Connected` to `jenkins.jenkins.svc.cluster.local:50000`.

Build 1 then succeeded. Jenkins pushed `acrvprofilel8.azurecr.io/vprofile-app:7198874f1e633a28e7f91fd723a37c17890ceda0` and committed that tag to `k8s/app.yaml` (`3fab761`). Argo CD sync is the next click. The login page will still look the same, because this image was built from the unchanged Java source.

## On the master

```bash
kubectl apply -f - <<'EOF'
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: jenkins-pods
  namespace: jenkins
rules:
  - apiGroups: [""]
    resources: ["pods", "pods/log"]
    verbs: ["get", "list", "watch", "create", "delete"]
  - apiGroups: [""]
    resources: ["pods/exec"]
    verbs: ["create", "get"]
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["get"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: jenkins-pods
  namespace: jenkins
subjects:
  - kind: ServiceAccount
    name: default
    namespace: jenkins
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: jenkins-pods
EOF

python3 - <<'PY'
import json, subprocess
raw = subprocess.check_output(["kubectl", "get", "secret", "acr-pull", "-n", "vprofile", "-o", "json"])
src = json.loads(raw)
out = {
    "apiVersion": "v1",
    "kind": "Secret",
    "metadata": {"name": "acr-pull", "namespace": "jenkins"},
    "type": src["type"],
    "data": src["data"],
}
subprocess.run(["kubectl", "apply", "-f", "-"], input=json.dumps(out).encode(), check=True)
PY
```

## Jenkins UI

**Manage Jenkins → Plugins → Available plugins.** Install **Kubernetes** and **Credentials Binding**. Let Jenkins restart in the same pod.

**Manage Jenkins → Clouds → New cloud → Kubernetes.**

| Field | Value |
|---|---|
| Name | `kubernetes` |
| Kubernetes URL | `https://kubernetes.default.svc` |
| Kubernetes namespace | `jenkins` |
| Credentials | none |
| Jenkins URL | `http://jenkins.jenkins.svc.cluster.local:8080` |

Click **Test Connection**. It must succeed before the job.

**New Item → Pipeline**, name `vprofile-build`.

| Field | Value |
|---|---|
| Definition | Pipeline script from SCM |
| SCM | Git |
| Repository URL | `https://github.com/omarmahgoubb/vprofile.git` |
| Credentials | `github-vprofile` |
| Branch | `*/main` |
| Script Path | `Jenkinsfile` |

Build it. The first run checks out `Jenkinsfile` at `7198874`, then creates a pod with containers `jnlp` and `kaniko`. Both stay `ContainerCreating` while those images download. Jenkins prints `offline` until the `jnlp` container connects. That wait is normal. `kubectl -n jenkins describe pod` Events show `Pulling` while it is healthy, and `Failed` or `ErrImagePull` if it is stuck.

Kaniko pushes `acrvprofilel8.azurecr.io/vprofile-app:<git commit>`, then Jenkins commits that tag into `k8s/app.yaml`. Argo CD stays manual: open `vprofile` and Sync after the job is green. The new pod must come up from ACR, not from `omarrmahgoub/vprofile-app:v1`.
