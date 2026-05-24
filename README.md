# KGT-LAB-DEVOPS

## Description
Reproduction et modernisation d'une architecture réseau virtuelle.
Remplacement de VirtualBox par KVM, automatisation avec Terraform + Ansible,
migration vers Kubernetes.

## Architecture cible
- Firewall  : srvsec  — IPFire
- LAN       : srvlan  — Debian (DNS, DHCP, Proxy)
- DMZ       : srvdmz  — Debian (LAMP, HTTPS, Postfix)
- Clients   : vm1, vm2 — Debian
- Switch    : Open vSwitch

## Phases
- Phase 1 : Terraform  — provisioning KVM
- Phase 2 : Ansible    — configuration services
- Phase 3 : CI/CD      — GitHub Actions
- Phase 4 : Kubernetes — migration conteneurs
