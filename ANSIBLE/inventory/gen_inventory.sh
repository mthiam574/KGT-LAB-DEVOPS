#!/usr/bin/env bash
# ─────────────────────────────────────
# Génère l'inventaire Ansible depuis KVM
# ─────────────────────────────────────

get_ip() {
  virsh --connect qemu:///system domifaddr "$1" \
    | awk '/ipv4/ {print $4}' \
    | cut -d/ -f1 \
    | head -n1
}

SRVLAN=$(get_ip srvlan)
SRVDMZ=$(get_ip srvdmz)
VM1=$(get_ip vm1)
VM2=$(get_ip vm2)
OVS=$(get_ip ovs)
cat > "$(dirname "$0")/hosts.yml" << EOF
all:
  vars:
    ansible_user: debian
    ansible_ssh_private_key_file: ~/.ssh/id_ed25519

  children:
    lan:
      hosts:
        srvlan:
          ansible_host: ${SRVLAN}
        vm1:
          ansible_host: ${VM1}
          vm_lan_ip: 192.168.3.2
        vm2:
          ansible_host: ${VM2}
          vm_lan_ip: 192.168.3.4
        ovs:
          ansible_host: ${OVS}
    dmz:
      hosts:
        srvdmz:
          ansible_host: ${SRVDMZ}
EOF
