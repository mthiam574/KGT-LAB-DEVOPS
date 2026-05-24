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
        vm2:
          ansible_host: ${VM2}

    dmz:
      hosts:
        srvdmz:
          ansible_host: ${SRVDMZ}
EOF

echo "✅ Inventaire généré :"
cat "$(dirname "$0")/hosts.yml"
