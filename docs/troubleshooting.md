---
title: Troubleshooting
nav_order: 5
---

# Troubleshooting

## terraform destroy échoue sur cloud-init

**Erreur** : `error while copying remote volume to local disk, bytesCopied 0 != volume.size`

**Cause** : bug du provider libvirt lors du refresh des ISOs cloud-init.

**Fix** :
```bash
terraform destroy -refresh=false
```

---

## srvsec ne boote pas après apply

**Erreur** : `Boot failed: not a bootable disk`

**Cause** : disque déclaré en `raw` au lieu de `qcow2` dans le XML libvirt.

**Fix** : utiliser `libvirt_volume` avec `format = "qcow2"` et `source = ipfire-golden.qcow2` au lieu de `disk { file = ... }`.

---

## OVS br0 sans IP après Ansible

**Cause** : `systemd-networkd` démarre avant qu'OVS crée br0 — il n'applique pas la config.

**Fix** : redémarrer `systemd-networkd` explicitement **après** toutes les tâches OVS.

---

## Ping srvlan → ovs échoue (ARP FAILED)

**Cause** : les réseaux `lab-lan/green/dmz` avaient `addresses` dans `main.tf` — libvirt assignait l'IP du bridge (ex: 192.168.3.1) à virbr, créant un conflit.

**Fix** : supprimer `addresses` sur les réseaux en `mode = none`.

---

## apt lock bloqué sur VMs fraîches

**Cause** : cloud-init tient le lock apt au démarrage.

**Fix** :
```yaml
- name: Attente libération lock apt
  shell: |
    while fuser /var/lib/dpkg/lock-frontend \
                /var/lib/apt/lists/lock \
                /var/cache/apt/archives/lock \
                >/dev/null 2>&1; do sleep 5; done
  timeout: 300
```
