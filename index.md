---
title: Accueil
nav_order: 1
---

# KGT Lab DevOps

Lab d'infrastructure virtualisée sur KVM/Libvirt — automatisé avec Terraform et Ansible.

---

## Architecture

| Composant | Rôle | IP |
|-----------|------|----|
| srvlan | Routeur LAN / NAT | 192.168.3.1 / 192.168.2.2 |
| srvsec | Firewall IPFire | GREEN 192.168.2.1 / ORANGE 192.168.4.1 |
| srvdmz | Serveur DMZ | 192.168.4.2 |
| ovs | Switch virtuel OVS | 192.168.3.15 |
| vm1 | Client LAN | 192.168.3.2 |
| vm2 | Client LAN | 192.168.3.4 |

---

## Démarrage rapide

```bash
cd TERRAFORM && terraform apply
cd ../ANSIBLE && ansible-playbook -i inventory/hosts.yml site.yml
```
