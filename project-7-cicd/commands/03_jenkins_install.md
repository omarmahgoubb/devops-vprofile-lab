# Jenkins controller on the kubeadm cluster

`ubuntu` (12 GB) stays powered off. Jenkins is one pod, pinned to **`k8s-worker2`**, so it does not sit on worker1 next to MySQL, Tomcat, RabbitMQ, Memcached, and nginx.

Heap is capped at 512 MB. Home directory is an `emptyDir`: deleting the pod wipes jobs and the admin user. That matches the lab DB volume. There is no default StorageClass for a real disk.

Manifest: [k8s/jenkins.yaml](../k8s/jenkins.yaml).

## Apply (on `k8s-master`)

```bash
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: jenkins
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jenkins
  namespace: jenkins
spec:
  replicas: 1
  selector:
    matchLabels:
      app: jenkins
  template:
    metadata:
      labels:
        app: jenkins
    spec:
      nodeSelector:
        kubernetes.io/hostname: k8s-worker2
      securityContext:
        fsGroup: 1000
      containers:
        - name: jenkins
          image: jenkins/jenkins:lts-jdk17
          ports:
            - name: http
              containerPort: 8080
          env:
            - name: JAVA_OPTS
              value: "-Xmx512m"
          resources:
            requests:
              cpu: "200m"
              memory: 768Mi
            limits:
              memory: 1536Mi
          readinessProbe:
            httpGet:
              path: /login
              port: 8080
            initialDelaySeconds: 60
            periodSeconds: 10
            timeoutSeconds: 5
            failureThreshold: 18
          volumeMounts:
            - name: jenkins-home
              mountPath: /var/jenkins_home
      volumes:
        - name: jenkins-home
          emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: jenkins
  namespace: jenkins
spec:
  type: NodePort
  selector:
    app: jenkins
  ports:
    - name: http
      port: 8080
      targetPort: 8080
      nodePort: 30082
EOF
kubectl -n jenkins get pods -o wide
```

The image is large (`jenkins/jenkins:lts-jdk17`, about 280 MB). On 16 Oct 2026 the first pod was **Evicted**: worker2 was under the kubelet ephemeral-storage threshold (about 1.7 GB free required, about 1.4 GB free). Exit code **143** is that kill, not a Jenkins bug. The replacement pod stayed **Pending** because both workers then had the `disk-pressure` taint, and the master does not run app pods.

Free space on **worker1** and **worker2** (unused container images and apt/journal cache):

```bash
df -h /
sudo crictl --runtime-endpoint unix:///var/run/containerd/containerd.sock rmi --prune
sudo journalctl --vacuum-size=100M
sudo apt-get clean
df -h /
```

Then on the master, `kubectl get nodes` should drop `disk-pressure`, and `kubectl -n jenkins get pods -o wide` should place Jenkins on worker2 again.

The installer had left the root filesystem at 12 GB on a larger LVM disk. On **worker1** and **worker2** (no reboot):

```bash
sudo lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
sudo resize2fs /dev/ubuntu-vg/ubuntu-lv
df -h /
```

Both grew to **23 GB** with about **14 GB** free. After that, `jenkins-57966c7c6b-q9qbt` was `1/1 Running` on `k8s-worker2`. The older pod stayed `Error` because it had been evicted; delete it so only the running pod remains:

```bash
kubectl -n jenkins delete pod jenkins-57966c7c6b-hjp6z
```

Wait until `1/1 Running`, then:

```bash
kubectl -n jenkins exec deploy/jenkins -- cat /var/jenkins_home/secrets/initialAdminPassword
```

After the workers froze and came back (16 Oct 2026), the first Jenkins pod was replaced. `emptyDir` does not follow the new pod, so the setup wizard and the admin user from the first pod were gone. New pod `jenkins-57966c7c6b-p6d2p` was `1/1 Running` on `k8s-worker2`. Read the password again. On the plugin page install only **Pipeline** and **Git** (not the full suggested set) so worker2 is not overloaded again.

Laptop: **http://192.168.56.124:30082**

That password is the one-time setup password. Do not commit it. After the account exists, Jenkins stores the user in `jenkins-home` (the emptyDir).

The UI reached **Welcome to Jenkins!** (Jenkins 2.541.3) while `k8s-worker1` was `NotReady` and `k8s-worker2` stayed `Ready`. Jenkins kept serving because the controller is pinned to worker2. The vprofile pods are on worker1, so that node still has to come back before the app URL is trustworthy.

Image builds later use Kaniko in the cluster. These nodes do not have Docker.
