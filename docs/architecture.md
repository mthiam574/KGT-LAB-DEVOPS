---
title: Architecture
nav_order: 2
---

# Architecture réseau

## Topologie
Internet
│
srvsec (IPFire)
RED=10.0.0.x │ GREEN=192.168.2.1 │ ORANGE=192.168.4.1
│                   │                    │
srvlan              srvdmz
192.168.3.1        192.168.4.2
192.168.2.2
│
ovs (OVS)
192.168.3.15
├── vm1 (192.168.3.2)
└── vm2 (192.168.3.4)

## Réseaux

| Réseau | CIDR | Mode | Rôle |
|--------|------|------|------|
| bootstrap | 192.168.100.0/24 | NAT | Management temporaire |
| lab-red | 10.0.0.0/24 | NAT | WAN IPFire |
| lab-green | 192.168.2.0/24 | none | srvlan ↔ IPFire |
| lab-lan | 192.168.3.0/24 | none | LAN principal |
| lab-dmz | 192.168.4.0/24 | none | Zone DMZ |
| ovs-vm1 | isolé | none | OVS ↔ vm1 |
| ovs-vm2 | isolé | none | OVS ↔ vm2 |
