# Bring the Lecture 6 cluster back (16 Oct 2026)

The three kubeadm VMs had been powered off for weeks. Start **`k8s-master`**, **`k8s-worker1`**, **`k8s-worker2`**. Leave **`ubuntu`** off until Jenkins.

Host-Only addresses (unchanged):

| Node | `enp0s3` |
|---|---|
| `k8s-master` | `192.168.56.124` |
| `k8s-worker1` | `192.168.56.127` |
| `k8s-worker2` | `192.168.56.128` |

## What `kubectl get nodes` showed

`k8s-master` `Ready`. Both workers `NotReady`. `kubectl get nodes -o wide` still listed worker InternalIP **`10.0.3.15`** (NAT, same on every VM). Flannel pods on the workers also showed `10.0.3.15`.

`describe node` said `Kubelet stopped posting node status` (last heartbeat 20 Sep 2026). On each worker, `containerd` was `active` and `kubelet` was `activating`.

## Cause 1 — swap came back

`journalctl -u kubelet` on both workers:

```text
failed to run Kubelet: running with swap on is not supported
/swap.img
```

Lecture 6 had run `swapoff`. A later boot turned Ubuntu’s `/swap.img` on again, so kubelet exited and the API kept the old NAT address.

On **worker1** and **worker2** (same block). This also sets kubelet `--node-ip` to that VM’s Host-Only address, which Lecture 6 had done only on the master:

```bash
sudo swapoff -a
sudo sed -i -E '/^[^#].*[[:space:]]swap[[:space:]]/ s/^/#/' /etc/fstab
sudo systemctl mask swap.img.swap
free -h
IP=$(ip -4 -o addr show enp0s3 | awk '{print $4}' | cut -d/ -f1)
echo "node-ip will be $IP"
sudo tee /var/lib/kubelet/kubeadm-flags.env >/dev/null <<EOF
KUBELET_KUBEADM_ARGS="--container-runtime-endpoint=unix:///var/run/containerd/containerd.sock --pod-infra-container-image=registry.k8s.io/pause:3.10 --node-ip=${IP}"
EOF
sudo systemctl restart kubelet
systemctl is-active kubelet
```

`free -h` must show `Swap: 0B`. `node-ip` printed `192.168.56.127` on worker1 and `192.168.56.128` on worker2. After that, `kubectl get nodes` on the master showed all three **Ready**.

## Cause 2 — nginx 502, then connection refused

Laptop **http://192.168.56.124:30080/** returned **502 Bad Gateway** from `nginx/1.31.5`.

`kubectl get pods -n vprofile -o wide`: `web01` and `app01` were `Running` on worker1, endpoint `10.244.1.9:8080`. `rmq01` was `ContainerCreating` (it had been unschedulable while both workers were `unreachable`).

`curl` to the app pod IP **connected** and then timed out with 0 bytes. `kubectl logs` showed Tomcat still deploying `ROOT.war` (TLD scan, then Spring `Mapped "{[/login]..."`). Nginx was up; Tomcat had opened port 8080 before the WAR was ready, so nginx returned 502.

A few minutes later `:30080` was **connection refused**. `iptables -t nat` had **no** `30080` rule. `k8s-worker1` was `NotReady` again. kube-proxy drops the NodePort when that node is not Ready, and every vprofile pod is on worker1.

Worker1 kubelet was `active` and swap was still `0B`. The log said:

```text
container runtime is down, PLEG is not healthy
ListPodSandbox ... context deadline exceeded
```

containerd had stopped answering. This 4 GB VM runs MySQL, Tomcat, RabbitMQ, Memcached, and nginx together, and Tomcat startup stalled the runtime.

On **worker1**:

```bash
systemctl is-active containerd
sudo systemctl restart containerd
sudo systemctl restart kubelet
systemctl is-active containerd kubelet
```

Master then showed all three nodes **Ready**. After Tomcat finished starting, the laptop login worked again: **http://192.168.56.124:30080/** (`admin_vp` / `admin_vp`).

`rmq01` Events also showed an earlier Flannel error, `open /run/flannel/subnet.env: no such file or directory`, from the minute kubelet came back before Flannel wrote that file. The image then pulled and the container started. That was not a separate fix.
