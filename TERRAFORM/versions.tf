terraform {
  required_version = ">= 1.6.0"

  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.7.6"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.0"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = ">= 2.3.0"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

