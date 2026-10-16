# First Jenkins pipeline (checkout only)

Controller UI is up: **http://192.168.56.124:30082**. This job does not compile and does not build an image. The Git repo has `k8s/vprofile.yaml` and no Java source, and a full image build is what overloaded the workers.

Script (same text as [Jenkinsfile](../Jenkinsfile)):

```groovy
pipeline {
    agent any
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/omarmahgoubb/devops-vprofile-lab.git'
            }
        }
        stage('Manifest') {
            steps {
                sh 'ls -l project-6-containers/k8s && echo CI reached the deploy folder'
            }
        }
    }
}
```

In the UI:

1. **New Item**
2. Name `vprofile-ci`
3. **Pipeline** → OK
4. Definition: **Pipeline script** (not “from SCM” yet; this file is not on GitHub until we push)
5. Paste the script → **Save** → **Build Now**
6. Open the build → **Console Output**

Success is a `Finished: SUCCESS` and a line `CI reached the deploy folder`, plus `vprofile.yaml` in the `ls` output.

`agent any` runs on the controller pod on `k8s-worker2`. No extra agent VM.

## First build (16 Oct 2026)

Started by user `mahgoub`. Workspace `/var/jenkins_home/workspace/vprofile-ci`. Cloned `https://github.com/omarmahgoubb/devops-vprofile-lab.git`, checked out `af15e0e` (`main`), message `Document the kubeadm deploy and dual-NIC fixes so Project 6 matches the live cluster.`

`ls` showed `vprofile.yaml` (4852 bytes). Console ended `CI reached the deploy folder` and `Finished: SUCCESS`.

No image was built and Argo was not synced. `af15e0e` does not contain `project-7-cicd/` or this `Jenkinsfile`. Those files are only on the laptop until the next push.
