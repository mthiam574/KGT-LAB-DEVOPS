variable "pool" {
  type    = string
  default = "default"
  description = "Pool de stockage libvirt"
}
variable "ssh_pubkey_path" {
  type    = string
  default = "~/.ssh/id_ed25519.pub"
  description = "Clé SSH publique pour accès aux VMs"
}
variable "image_url" {
  type        = string
  description = "URL de téléchargement de l image Debian cloud"
  default     = "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2"
}

variable "image_name" {
  type        = string
  description = "Nom du fichier image"
  default     = "debian-12-genericcloud-amd64.qcow2"
}
