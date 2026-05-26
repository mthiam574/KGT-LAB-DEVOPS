# ─────────────────────────────────────────
# Locals
# ─────────────────────────────────────────
locals {
  image_path = "${path.module}/${var.image_name}"
  public_key = file(pathexpand(var.ssh_pubkey_path))
}

# ─────────────────────────────────────────
# Réseau bootstrap (NAT temporaire)
# ─────────────────────────────────────────
resource "libvirt_network" "bootstrap" {
  name      = "bootstrap"
  mode      = "nat"
  addresses = ["192.168.100.0/24"]

  dhcp {
    enabled = true
  }

  dns {
    enabled = true
  }
}

# ─────────────────────────────────────────
# Réseau LAN interne (192.168.3.0/24)
# srvlan ↔ vm1/vm2
# ─────────────────────────────────────────
resource "libvirt_network" "lan" {
  name      = "lab-lan"
  mode      = "none"
  addresses = ["192.168.3.0/24"]

  dhcp {
    enabled = false
  }
}

# ─────────────────────────────────────────
# Réseau GREEN (192.168.2.0/24)
# IPFire ↔ srvlan
# ─────────────────────────────────────────
resource "libvirt_network" "green" {
  name      = "lab-green"
  mode      = "none"
  addresses = ["192.168.2.0/24"]

  dhcp {
    enabled = false
  }
}

# ─────────────────────────────────────────
# Réseau DMZ (192.168.4.0/24)
# IPFire ↔ srvdmz
# ─────────────────────────────────────────
resource "libvirt_network" "dmz" {
  name      = "lab-dmz"
  mode      = "none"
  addresses = ["192.168.4.0/24"]

  dhcp {
    enabled = false
  }
}
# ─────────────────────────────────────────
# Réseau isolé ovs ↔ vm1
# ─────────────────────────────────────────
resource "libvirt_network" "ovs_vm1" {
  name = "ovs-vm1"
  mode = "none"
}
# ─────────────────────────────────────────
# Réseau isolé ovs ↔ vm2
# ─────────────────────────────────────────
resource "libvirt_network" "ovs_vm2" {
  name = "ovs-vm2"
  mode = "none"
}
# ─────────────────────────────────────────
# Réseau RED/WAN (10.0.0.0/24)
# IPFire WAN
# ─────────────────────────────────────────
resource "libvirt_network" "red" {
  name      = "lab-red"
  mode      = "nat"
  addresses = ["10.0.0.0/24"]

  dhcp {
    enabled = true
  }
}

# ─────────────────────────────────────────
# Téléchargement image Debian si absente
# ─────────────────────────────────────────
resource "null_resource" "download_image" {
  triggers = {
    image_url = var.image_url
  }

  provisioner "local-exec" {
    command = <<-EOF
      if [ ! -f "${local.image_path}" ]; then
        echo ">>> Téléchargement image Debian..."
        wget -q -O "${local.image_path}" "${var.image_url}"
      else
        echo ">>> Image déjà présente, on continue."
      fi
    EOF
  }
}

# ─────────────────────────────────────────
# Volume disque srvlan
# ─────────────────────────────────────────
resource "libvirt_volume" "srvlan" {
  depends_on = [null_resource.download_image]
  name       = "srvlan-os.qcow2"
  pool       = var.pool
  source     = local.image_path
  format     = "qcow2"
}

# ─────────────────────────────────────────
# Cloud-init srvlan
# ─────────────────────────────────────────
data "cloudinit_config" "srvlan" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/cloud_init.cfg", {
      hostname   = "srvlan"
      fqdn       = "srvlan.lab.local"
      public_key = local.public_key
    })
  }

  part {
    content_type = "text/network-config"
    content      = file("${path.module}/network_config_dhcp.cfg")
  }
}

resource "libvirt_cloudinit_disk" "srvlan" {
  name      = "srvlan-cloudinit.iso"
  pool      = var.pool
  user_data = data.cloudinit_config.srvlan.rendered
}

# ─────────────────────────────────────────
# VM srvlan
# ─────────────────────────────────────────
resource "libvirt_domain" "srvlan" {
  name   = "srvlan"
  memory = 1024
  vcpu   = 1

  disk {
    volume_id = libvirt_volume.srvlan.id
  }

  network_interface {
    network_id     = libvirt_network.bootstrap.id
    wait_for_lease = true
  }

  network_interface {
    network_id = libvirt_network.lan.id
  }

  network_interface {
    network_id = libvirt_network.green.id
  }


  cloudinit = libvirt_cloudinit_disk.srvlan.id

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type     = "spice"
    autoport = true
  }
}

# ─────────────────────────────────────────
# Volume disque srvdmz
# ─────────────────────────────────────────
resource "libvirt_volume" "srvdmz" {
  depends_on = [null_resource.download_image]
  name       = "srvdmz-os.qcow2"
  pool       = var.pool
  source     = local.image_path
  format     = "qcow2"
}

# ─────────────────────────────────────────
# Cloud-init srvdmz
# ─────────────────────────────────────────
data "cloudinit_config" "srvdmz" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/cloud_init.cfg", {
      hostname   = "srvdmz"
      fqdn       = "srvdmz.lab.local"
      public_key = local.public_key
    })
  }

  part {
    content_type = "text/network-config"
    content      = file("${path.module}/network_config_dhcp.cfg")
  }
}

resource "libvirt_cloudinit_disk" "srvdmz" {
  name      = "srvdmz-cloudinit.iso"
  pool      = var.pool
  user_data = data.cloudinit_config.srvdmz.rendered
}

# ─────────────────────────────────────────
# VM srvdmz
# ─────────────────────────────────────────
resource "libvirt_domain" "srvdmz" {
  name   = "srvdmz"
  memory = 1024
  vcpu   = 1

  disk {
    volume_id = libvirt_volume.srvdmz.id
  }

  network_interface {
    network_id     = libvirt_network.bootstrap.id
    wait_for_lease = true
  }

  network_interface {
    network_id = libvirt_network.dmz.id
  }

  cloudinit = libvirt_cloudinit_disk.srvdmz.id

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type     = "spice"
    autoport = true
  }
}

# ─────────────────────────────────────────
# Volume disque vm1
# ─────────────────────────────────────────
resource "libvirt_volume" "vm1" {
  depends_on = [null_resource.download_image]
  name       = "vm1-os.qcow2"
  pool       = var.pool
  source     = local.image_path
  format     = "qcow2"
}

# ─────────────────────────────────────────
# Cloud-init vm1
# ─────────────────────────────────────────
data "cloudinit_config" "vm1" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/cloud_init.cfg", {
      hostname   = "vm1"
      fqdn       = "vm1.lab.local"
      public_key = local.public_key
    })
  }

  part {
    content_type = "text/network-config"
    content      = file("${path.module}/network_config_dhcp.cfg")
  }
}

resource "libvirt_cloudinit_disk" "vm1" {
  name      = "vm1-cloudinit.iso"
  pool      = var.pool
  user_data = data.cloudinit_config.vm1.rendered
}

# ─────────────────────────────────────────
# VM vm1
# ─────────────────────────────────────────
resource "libvirt_domain" "vm1" {
  name   = "vm1"
  memory = 1024
  vcpu   = 1

  disk {
    volume_id = libvirt_volume.vm1.id
  }

  network_interface {
    network_id     = libvirt_network.bootstrap.id
    wait_for_lease = true
  }

  network_interface {
    network_id = libvirt_network.ovs_vm1.id
  }

  cloudinit = libvirt_cloudinit_disk.vm1.id

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type     = "spice"
    autoport = true
  }
}

# ─────────────────────────────────────────
# Volume disque vm2
# ─────────────────────────────────────────
resource "libvirt_volume" "vm2" {
  depends_on = [null_resource.download_image]
  name       = "vm2-os.qcow2"
  pool       = var.pool
  source     = local.image_path
  format     = "qcow2"
}

# ─────────────────────────────────────────
# Cloud-init vm2
# ─────────────────────────────────────────
data "cloudinit_config" "vm2" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/cloud_init.cfg", {
      hostname   = "vm2"
      fqdn       = "vm2.lab.local"
      public_key = local.public_key
    })
  }

  part {
    content_type = "text/network-config"
    content      = file("${path.module}/network_config_dhcp.cfg")
  }
}

resource "libvirt_cloudinit_disk" "vm2" {
  name      = "vm2-cloudinit.iso"
  pool      = var.pool
  user_data = data.cloudinit_config.vm2.rendered
}

# ─────────────────────────────────────────
# VM vm2
# ─────────────────────────────────────────
resource "libvirt_domain" "vm2" {
  name   = "vm2"
  memory = 1024
  vcpu   = 1

  disk {
    volume_id = libvirt_volume.vm2.id
  }

  network_interface {
    network_id     = libvirt_network.bootstrap.id
    wait_for_lease = true
  }

  network_interface {
    network_id = libvirt_network.ovs_vm2.id
  }

  cloudinit = libvirt_cloudinit_disk.vm2.id

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type     = "spice"
    autoport = true
  }
}
# ─────────────────────────────────────────
# Volume disque ovs
# ─────────────────────────────────────────
resource "libvirt_volume" "ovs" {
  depends_on = [null_resource.download_image]
  name       = "ovs-os.qcow2"
  pool       = var.pool
  source     = local.image_path
  format     = "qcow2"
}
# ─────────────────────────────────────────
# Cloud-init ovs
# ─────────────────────────────────────────
data "cloudinit_config" "ovs" {
  gzip          = false
  base64_encode = false
  part {
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/cloud_init.cfg", {
      hostname   = "ovs"
      fqdn       = "ovs.lab.local"
      public_key = local.public_key
    })
  }
}
resource "libvirt_cloudinit_disk" "ovs" {
  name      = "ovs-cloudinit.iso"
  pool      = var.pool
  user_data = data.cloudinit_config.ovs.rendered
}
# ─────────────────────────────────────────
# VM ovs (Open vSwitch)
# ─────────────────────────────────────────
resource "libvirt_domain" "ovs" {
  name   = "ovs"
  memory = 1024
  vcpu   = 2
  disk {
    volume_id = libvirt_volume.ovs.id
  }
  network_interface {
    network_id     = libvirt_network.bootstrap.id
    wait_for_lease = true
  }
  network_interface {
    network_id     = libvirt_network.lan.id
    wait_for_lease = false
  }
  network_interface {
    network_id     = libvirt_network.ovs_vm1.id
    wait_for_lease = false
  }
  network_interface {
    network_id     = libvirt_network.ovs_vm2.id
    wait_for_lease = false
  }
  cloudinit = libvirt_cloudinit_disk.ovs.id
  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }
  graphics {
    type     = "spice"
    autoport = true
  }
}
# ─────────────────────────────────────────
# Téléchargement ISO IPFire si absent
# ─────────────────────────────────────────
#resource "null_resource" "download_ipfire" {
#  triggers = {
#    iso_url = var.ipfire_iso_url
#  }
#
#  provisioner "local-exec" {
#    command = <<-EOF
#      if [ ! -f "${path.module}/${var.ipfire_iso_name}" ]; then
#        echo ">>> Téléchargement ISO IPFire..."
#        wget -q -O "${path.module}/${var.ipfire_iso_name}" "${var.ipfire_iso_url}"
#      else
#        echo ">>> ISO IPFire déjà présent, on continue."
#      fi
#    EOF
#  }
#}
#
## ─────────────────────────────────────────
## Volume ISO IPFire
## ─────────────────────────────────────────
#resource "libvirt_volume" "ipfire_iso" {
#  depends_on = [null_resource.download_ipfire]
#  name       = var.ipfire_iso_name
#  pool       = var.pool
#  source     = "${path.module}/${var.ipfire_iso_name}"
#  format     = "raw"
#}
## ─────────────────────────────────────────
## Volume disque srvsec (IPFire)
# ─────────────────────────────────────────
resource "libvirt_volume" "srvsec" {
  name   = "srvsec-os.qcow2"
  pool   = var.pool
  format = "qcow2"
  source = "/var/lib/libvirt/images/ipfire-golden.qcow2"
}

# ─────────────────────────────────────────
# VM srvsec (IPFire)
# ─────────────────────────────────────────
resource "libvirt_domain" "srvsec" {
  name   = "srvsec"
  memory = 2048
  vcpu   = 2

  disk {
    volume_id = libvirt_volume.srvsec.id
  }
  disk {
    volume_id = libvirt_volume.srvsec.id
  }

  network_interface {
    network_id     = libvirt_network.bootstrap.id
    mac            = "52:54:00:aa:45:e7"
    wait_for_lease = false
  }
  network_interface {
    network_id     = libvirt_network.red.id
    mac            = "52:54:00:a6:18:4e"
    wait_for_lease = false
  }
  network_interface {
    network_id     = libvirt_network.green.id
    mac            = "52:54:00:1e:fe:c5"
    wait_for_lease = false
  }
  network_interface {
    network_id     = libvirt_network.dmz.id
    mac            = "52:54:00:2a:d6:44"
    wait_for_lease = false
  }
  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type     = "spice"
    autoport = true
  }
}

# ─────────────────────────────────────────
# Génération automatique inventaire Ansible
# ─────────────────────────────────────────
resource "null_resource" "gen_inventory" {
  depends_on = [
    libvirt_domain.srvlan,
    libvirt_domain.srvdmz,
    libvirt_domain.vm1,
    libvirt_domain.vm2,
    libvirt_domain.ovs
  ]

  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "bash ${path.module}/../ANSIBLE/inventory/gen_inventory.sh"
  }
}
