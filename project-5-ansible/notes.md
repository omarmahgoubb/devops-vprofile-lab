# Personal notes — Lecture 5 (Ansible / AWX)

On-prem stack is still 5 VMs (`db01`–`web01`). Azure stack is the Lecture 4 VMs.

This lecture: **one controller VM** runs Ansible. AWX is the website on top.

Controller choice: **Vagrant Ubuntu, 8 GB RAM** (`awx01`, `192.168.56.20`). Not Azure.

- Task 1: **done.** AWX on `awx01`, http://127.0.0.1:8088.
- Task 2: **done.** Ansible Core + ping on all five on-prem VMs.
- Task 3: **done.** Playbooks ran; site http://192.168.56.11 (`admin_vp` / `admin_vp`). Always `-i ~/ansible/hosts.ini`.

AWX notes from class use Ubuntu + Docker + minikube + operator. 4 GB is not enough. This box is **8192 MB**.
