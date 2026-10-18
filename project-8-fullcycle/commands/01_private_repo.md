# Private app repo (17 Oct 2026)

The lab notes repo does not contain the Java UI. The class app does.

Source: `https://github.com/hkhcoder/vprofile-project.git` branch `main`.  
Private copy: `https://github.com/omarmahgoubb/vprofile.git`  
Local folder: `Lecture8_fullcycle/vprofile`.

## Clone

```bash
git clone --depth 1 -b main https://github.com/hkhcoder/vprofile-project.git Lecture8_fullcycle/vprofile
```

The class `Jenkinsfile` was renamed to `ci-class-Jenkinsfile` so our pipeline file can occupy `Jenkinsfile`.

## Files added

| File | Why |
|---|---|
| `Dockerfile` | Multi-stage. Maven builds `vprofile-v2.war` (`pom.xml` version `v2`). Runtime is `tomcat:8-jre11`, same as Lecture 6. |
| `k8s/app.yaml` | Namespace `vprofile`, Deployment `app01`, image `omarrmahgoub/vprofile-app:v1`, Service NodePort **30080**. Jenkins is meant to replace the tag. |
| `Jenkinsfile` | Stages `Build` (`mvn -B -DskipTests package`), `Image` (prints `omarrmahgoub/vprofile-app:$GIT_COMMIT`), `Git tag` (`sed` on `k8s/app.yaml`). That name is the old Docker Hub placeholder. The registry is now ACR Basic. No ACR login and no Kaniko in this file yet. |
| `.gitignore` | `target/`, `*.war`. |
| `README.md` | What the private repo is for. |

`login.jsp` titles a later edit can change:

- `<title>LOGIN</title>`
- `WELCOME!`
- navbar `HKH Infotech`

## Push

GitHub CLI is not installed on this PC. The empty private repo was created in the browser (no README, no license).

`origin` had been the class repo. It was renamed to `upstream`. The private repo became `origin` over HTTPS (not SSH).

First `git push -u origin main` failed:

```text
remote: fatal: did not receive expected object 982adfe744fe6f4ffc61055d97bb1f2735d90c5f
error: remote unpack failed: index-pack failed
```

Cause: `git clone --depth 1` did not have the parent objects GitHub required. Fix:

```bash
git fetch --unshallow upstream
git push -u origin main
```

Result: `main` is on https://github.com/omarmahgoubb/vprofile (`c26d077` from the class repo, plus `7e2d316` for the Dockerfile, manifest, and Jenkinsfile).

Nothing was pushed to `hkhcoder/vprofile-project`.
