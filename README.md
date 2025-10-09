# DevOps VProfile Lab — Manual → Automation → Monitoring

This monorepo documents my journey from **manual provisioning** to **automated builds** and **monitoring** for a multi-tier Java web application.

## What’s inside (current)
- **project-1-manual/** — SSH-based manual setup (per host) with exact commands I ran.
- **docs/** — architecture notes and ports.

Next steps will add:
- **project-2-automation/** — shell-scripted provisioning with Vagrant provisioners.
- **project-3-monitoring-nagios/** — Nagios Core + NRPE checks for the same stack.


## Interactive walkthrough
- **Code2Tutorial (auto-generated guide)** — A click‑through tutorial for this repo with chapters and code/command blocks:  
  👉 https://code2tutorial.com/tutorial/3cab15e6-750e-4e20-a74c-2ace648c7745/index.md  
  *What it does:* uses the Code2Tutorial engine to analyze the repo and render a human‑readable walkthrough that explains structure, components, and setup so newcomers can follow along quickly.


## Stack & order
- **Services**: Nginx (web), Tomcat (app), RabbitMQ (broker), Memcached (cache), MySQL (DB).
- **Bring-up order**: MySQL → Memcached → RabbitMQ → Tomcat → Nginx (so dependencies are ready first).

## Quickstart (Project 1)
1. Ensure you have **VirtualBox** and **Vagrant** installed.
2. Install the host manager plugin (on your workstation):  
   `vagrant plugin install vagrant-hostmanager`
3. Use the provided commands per host under `project-1-manual/commands/` (or adapt to your environment).

> ⚠️ Replace any sample credentials (e.g., `admin123`) with your own. Do not commit secrets. Use a local `.env` (git-ignored) for real values.

## Folder layout
```
devops-vprofile-lab/
├─ README.md
├─ .gitignore
├─ docs/
│  └─ architecture.md
└─ project-1-manual/
   ├─ README.md
   └─ commands/
      ├─ db01_mysql.md
      ├─ mc01_memcache.md
      ├─ rmq01_rabbitmq.md
      ├─ app01_tomcat.md
      └─ web01_nginx.md
```

## Why manual first?
Doing it by hand once makes the **automation spec obvious**. Each command becomes a line in a script with idempotence and error handling—then we validate it with monitoring.
