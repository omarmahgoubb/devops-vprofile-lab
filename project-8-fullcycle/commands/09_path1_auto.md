# 09 — Path 1: webhook, then Argo applies by itself

A push to `main` notifies Jenkins. Jenkins builds and commits the image tag. Argo CD applies that commit. No **Build Now** and no **Sync** click.

The webhook is `http://40.87.97.146:30082/github-webhook/`. Port 30082 is already open. Do not also enable **Poll SCM**.

## 1. Jenkins job `vprofile-build`

**Configure → Triggers.** Check **GitHub hook trigger for GITScm polling**. Leave **Poll SCM** unchecked.

**Pipeline → Git → Add → Polling ignores commits with certain messages.** Excluded Messages:

```text
^Set app image to
```

Save before adding the webhook. That pattern is the commit Jenkins itself pushes. Without it, the webhook starts another build forever.

## 2. GitHub webhook

Repo **omarmahgoubb/vprofile** → **Settings → Webhooks → Add webhook**.

| Field | Value |
|---|---|
| Payload URL | `http://40.87.97.146:30082/github-webhook/` |
| Content type | `application/json` |
| Secret | empty |
| SSL verification | disable (the URL is HTTP) |
| Events | Just the push event |

The trailing slash is required. A recent delivery should be a green check after the next push.

## 3. Argo CD, on the master

```bash
kubectl -n argocd patch application vprofile --type merge -p '{"spec":{"syncPolicy":{"automated":{"prune":false,"selfHeal":true},"syncOptions":["CreateNamespace=true"]}}}'
kubectl -n argocd get application vprofile -o jsonpath="{.spec.syncPolicy}"; echo
```

`automated` must be present. `prune` stays false so Argo does not delete MariaDB, Memcached, or RabbitMQ.

Argo automated sync is on: `prune` false, `selfHeal` true.

The first proof push started build #3. That build committed an image tag, the webhook started #4, and #4 queued #5. The UI ignore rule did not stop those tag commits. The Jenkinsfile now skips a commit whose subject starts with `Set app image to`, so a tag commit cannot create another tag commit.

## Proof

Commit `46bfa43` set the heading to `welcome omar` and forced `.navbar-custom` to `#c0392b` after the Bootswatch link. `profile.css` alone stayed dark because Bootswatch loads later.

Jenkins tagged `acrvprofilel8.azurecr.io/vprofile-app:46bfa431f4a10ebfed936c11f594f9805a312b90` in commit `7423cb0`. Argo rolled pod `app01-db7487bd7-442bl`. After Ctrl+F5, `http://40.87.97.146:30080` showed the red bar and `welcome omar`.
