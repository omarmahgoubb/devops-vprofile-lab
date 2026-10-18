# 07 — Jenkins controller (apply on the master)

This file is not in the private repo. Argo CD watches `k8s/` there, and a sync must not replace the Jenkins controller.

No `nodeSelector`. The master is tainted `control-plane:NoSchedule`, so the pod lands on `vm-vprofile-worker`. Lecture 7 pinned Jenkins to `k8s-worker2`, which does not exist here.

Heap cap is 512 MB. Request 768Mi, limit 1536Mi. Home is an `emptyDir`: replacing the pod wipes the admin user and jobs.

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
    - name: jnlp
      port: 50000
      targetPort: 50000
EOF
kubectl -n jenkins get pods -o wide
```

When the pod is `1/1 Running`:

```bash
kubectl -n jenkins exec deploy/jenkins -- cat /var/jenkins_home/secrets/initialAdminPassword
```

UI: **http://40.87.97.146:30082**. Do not install the suggested plugin set. Select only Folders, OWASP Markup Formatter, Pipeline, Git, and GitHub. Do not commit the password.

The Welcome page loaded. Executors showed `0/2`. The controller image has no Maven and no Docker. Do not install Docker on the VMs. containerd stays the kubelet runtime. Image builds use Kaniko. The ACR admin username is `acrvprofilel8`. The cluster pull secret name is `acr-pull` in namespace `vprofile`. `k8s/app.yaml` references that secret. The password is not stored in this repo. Jenkins credential IDs are `acr-vprofile` and `github-vprofile`.
