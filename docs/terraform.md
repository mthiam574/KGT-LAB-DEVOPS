---
title: Terraform
nav_order: 3
---

# Terraform

## Prérequis

- Provider `dmacvicar/libvirt`
- Image Debian 12 cloud : `debian-12-genericcloud-amd64.qcow2`
- Golden image IPFire : `ipfire-golden.qcow2`

## Déploiement

```bash
cd TERRAFORM
terraform init
terraform apply
```

## Ressources

| Ressource | Type | Description |
|-----------|------|-------------|
| libvirt_network | 7 réseaux | bootstrap, red, green, lan, dmz, ovs-vm1, ovs-vm2 |
| libvirt_volume | 6 volumes | srvlan, srvdmz, ovs, vm1, vm2, srvsec |
| libvirt_domain | 6 VMs | toutes les machines du lab |
| null_resource | gen_inventory | génère hosts.yml Ansible automatiquement |

## Points importants

- `lab-lan`, `lab-green`, `lab-dmz` en mode `none` — pas d'adresses gérées par libvirt
- `srvsec` utilise `libvirt_volume` avec `source = ipfire-golden.qcow2` pour garantir le format `qcow2`
- Le destroy nécessite `-refresh=false` pour éviter un bug du provider sur les ISOs cloud-init
