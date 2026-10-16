# Install Argo CD on the kubeadm cluster (16 Oct 2026)

Argo CD is the deployment half. It runs as pods in namespace `argocd` on the Lecture 6 cluster. It does not build images.

Work on **`k8s-master`**.

## Install

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl -n argocd get pods
```

What applied: CRDs `applications.argoproj.io` and `appprojects.argoproj.io`, ServiceAccounts, RBAC, ConfigMaps, the server / repo-server / redis / dex / notifications Deployments, and the application-controller StatefulSet.

**One error, safe to continue:**

```text
The CustomResourceDefinition "applicationsets.argoproj.io" is invalid:
metadata.annotations: Too long: may not be more than 262144 bytes
```

`kubectl apply` stores the whole object in an annotation. That ApplicationSet CRD is bigger than 256 KB, so it was skipped. One vprofile Application does not use ApplicationSets. `argocd-applicationset-controller` still started and restarted several times; ignore it for this lab.

Image we pulled: `quay.io/argoproj/argocd:v3.5.5`.

A second `argocd-repo-server` pod was `ContainerStatusUnknown` (left over from worker1 being `NotReady`). Deleted:

```bash
kubectl -n argocd delete pod argocd-repo-server-79d854996b-f2lls
```

## Publish the UI

Goal: laptop **http://192.168.56.124:30081**, plain HTTP, user `admin`.

First attempt (do **not** repeat). This replaced the container args with only `--insecure`:

```bash
kubectl -n argocd patch deployment argocd-server --type strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"argocd-server","args":["--insecure"]}]}}}}'
kubectl -n argocd patch svc argocd-server -p '{"spec":{"type":"NodePort","ports":[{"name":"http","port":80,"targetPort":8080,"nodePort":30081}]}}'
```

`rollout status` sat on `1 old replicas are pending termination`. The new pod `argocd-server-78866f5bd5-xqx2f` on worker1 was `CrashLoopBackOff`, **exit code 127** (command not found). v3.5’s container arguments start with the real binary path. Replacing that whole list made the image try to execute a program named `--insecure`. The old pod on worker2 stayed `Running`.

`Ctrl+C` on `rollout status` does not undo a patch. The admin password command only ran after that wait ended:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```

Do not commit that password.

## Fix: roll back, set insecure in the ConfigMap

```bash
kubectl -n argocd rollout undo deploy/argocd-server --to-revision=1
kubectl -n argocd patch configmap argocd-cmd-params-cm --type merge -p '{"data":{"server.insecure":"true"}}'
kubectl -n argocd patch deployment argocd-server --type json -p '[{"op":"replace","path":"/spec/template/spec/containers/0/readinessProbe/httpGet/scheme","value":"HTTP"}]'
kubectl -n argocd get pods -l app.kubernetes.io/name=argocd-server -o wide
```

Result:

- Rollback succeeded. CrashLoop pod went `Terminating`, then disappeared.
- ConfigMap patch succeeded. Argo CD 3.5 reads `server.insecure` from `argocd-cmd-params-cm`.
- Readiness probe patch said **patched (no change)**. v3.5’s probe was already `HTTP`.
- One pod left: `argocd-server-584bbfd999-qc8tw` `1/1 Running` on `k8s-worker2` (`10.244.2.12`). That pod is still the original process. It has **not** reloaded `server.insecure`.

The NodePort patch on `argocd-server` (port 80 → target 8080 → nodePort **30081**) stayed in place. It was not part of the Deployment rollback.

## Restart so the server reads `server.insecure`

The pod from the rollback was still the original process. Restart it:

```bash
kubectl -n argocd rollout restart deploy/argocd-server
kubectl -n argocd get pods -l app.kubernetes.io/name=argocd-server -o wide
```

Wait until the new pod is `1/1 Running`.

## UI check (16 Oct 2026)

Laptop: **http://192.168.56.124:30081**  
User `admin`. Password from the secret command above (do not commit it).

The page loaded: Argo CD **v3.5.5**, Applications, “No applications available to you just yet”.

## Which Git repo

This lab’s manifests are already in the repo we push from the Windows clone:

```text
https://github.com/omarmahgoubb/devops-vprofile-lab.git
```

Confirm on the PC (PowerShell), from the clone:

```powershell
git remote -v
```

`origin` is that URL. The file Argo must watch is not the whole repo (that includes Projects 1–6 READMEs). It is only:

```text
project-6-containers/k8s
```

That folder contains `vprofile.yaml`. Branch is `main`.

## Application created (16 Oct 2026)

In the UI (**NEW APP**), manual sync, no sync-option checkboxes:

| Field | Value |
|---|---|
| Application Name | `vprofile` |
| Project | `default` |
| Repository URL | `https://github.com/omarmahgoubb/devops-vprofile-lab.git` |
| Revision | `main` |
| Path | `project-6-containers/k8s` |
| Cluster URL | `https://kubernetes.default.svc` (shown as in-cluster) |
| Namespace | `vprofile` |

Card after create: **Healthy** and **OutOfSync**. Healthy means the pods already running in `vprofile` are fine. OutOfSync means those objects were created earlier with `kubectl apply`, so they do not yet carry Argo’s tracking labels.

The resource tree (before Sync) shows the live objects: namespace, ConfigMap `web01-nginx`, one Service and one Deployment per role, Job `db01-grant`. Green heart = running. Yellow dot = not yet recorded as in sync. ReplicaSet boxes under `web01` (`rev:1` … `rev:6`) are old Deployment rollouts, not extra sites. One `mc01` pod was `ContainerStatusUnknown` from the earlier containerd stall; the other was `Running`.

**Sync** was clicked with **Prune** left off. The app became **Synced**, and **http://192.168.56.124:30080/** still opened. From here, a change to `project-6-containers/k8s` in Git is what Argo deploys. Jenkins is the next step, and it is what will make that Git change.

`mc01` is `replicas: 1` and still shows two pods on the same ReplicaSet (`mc01-78d6f84845`). One is `Running`. The other is `ContainerStatusUnknown` from when worker1’s containerd stopped answering. The Service sends traffic only to the ready pod. The unknown pod is leftover, not a second memcached the YAML asked for.
