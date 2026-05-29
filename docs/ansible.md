---
title: Ansible
nav_order: 4
---

# Ansible

## Lancement

```bash
cd ANSIBLE
ansible-playbook -i inventory/hosts.yml site.yml
```

## Structure

ANSIBLE/
├── ansible.cfg          # host_key_checking = False
├── inventory/
│   ├── hosts.yml        # généré automatiquement par Terraform
│   └── gen_inventory.sh
├── roles/
│   ├── common/          # apt, outils de base, timezone
│   ├── network/         # IPs fixes, routes, NAT
│   │   ├── srvlan.yml
│   │   ├── srvdmz.yml
│   │   └── vm.yml
│   └── ovs/             # Open vSwitch + bridges
└── site.yml

## Plays

| Play | Hosts | Rôle |
|------|-------|------|
| Mise à jour known_hosts | localhost | SSH keys auto |
| Configuration commune | all | apt, outils, timezone |
| Configuration réseau | srvlan, srvdmz, vm1, vm2 | IPs, routes, NAT |
| Configuration OVS | ovs | bridges br0/br1/br2 |
| Validation connectivité | srvlan | pings de bout en bout |

## Points importants

- `cache_valid_time` retiré — update_cache toujours forcé sur VMs fraîches
- Routes persistantes via `nmcli routes4` format string : `"192.168.4.0/24 192.168.2.1"`
- OVS configuré via `ovs-vsctl` + `systemd-networkd` pour br0
- `systemd-networkd` redémarré **après** création des bridges OVS
