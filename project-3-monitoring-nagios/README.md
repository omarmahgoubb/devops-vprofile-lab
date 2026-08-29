# Project 3 — Monitoring the VMs with Nagios

This project adds a **Nagios Core** server (`mon01`) to monitor the 5 VMs from Project 2 (db01, mc01, rmq01, app01, web01). The provided provisioner installs Nagios and HTTPD, opens the right ports, and registers the five hosts for basic **ping availability** checks.

> The provisioning script included here is the exact one I used, placed under `scripts/nagios_provision.sh`.

## Topology
- `mon01` — Nagios Core + Apache (HTTP UI on port 80)
- Targets: `db01`, `mc01`, `rmq01`, `app01`, `web01` (from Project 2)

## Quickstart
1. Bring up the Project 2 VMs first (so the hosts exist on the network).
2. From this folder:
   ```bash
   vagrant up
   ```
   This boots `mon01` and runs `scripts/nagios_provision.sh`.

3. Create a Nagios web user (first-time setup):
   ```bash
   sudo htpasswd -c /etc/nagios/passwd nagiosadmin
   sudo systemctl restart httpd
   ```
4. Open the UI: `http://mon01/` (or `http://192.168.56.16/`) and sign in as `nagiosadmin`.

## Notes
- The script currently configures **Ping** checks for each host. You can extend monitoring by:
  - Adding `check_tcp` services for ports (3306, 11211, 5672, 8080, 80).
  - Or installing **NRPE** on each target and using `check_nrpe` for deeper app health checks.
- Make sure the IPs in `/etc/nagios/objects/clients.cfg` match **Project 2**: `web01=192.168.56.11`, `app01=.12`, `rmq01=.13`, `mc01=.14`, `db01=.15`.
