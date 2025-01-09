terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  token     = var.yandex_token
  cloud_id  = var.yandex_cloud_id
  folder_id = var.yandex_folder_id
  zone      = var.yandex_zone
}

resource "yandex_compute_instance" "vm" {
  name = var.vm_name

  resources {
    cores  = var.vm_cores
    memory = var.vm_memory
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.default.id
    nat       = true
  }

  metadata = {
    ssh-keys = "regina:ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIBb3GHLLen70A0nwelg/oTdfw0P2bRGVAtMEwbhOBwQ"
  }
}

resource "yandex_vpc_network" "default" {
  name = "default-network"
}

resource "yandex_vpc_subnet" "default" {
  name           = "default-subnet"
  network_id     = yandex_vpc_network.default.id
  zone           = var.yandex_zone
  v4_cidr_blocks = ["10.0.0.0/24"]
}

variable "yandex_token" {}
variable "yandex_cloud_id" {}
variable "yandex_folder_id" {}
variable "yandex_zone" {
  default = "ru-central1-d"
}
variable "vm_name" {
  default = "my-vm"
}
variable "vm_cores" {
  default = 2
}
variable "vm_memory" {
  default = 4  
}
variable "image_id" {
  default = "fd895e9j3al6len7lg24"
}
variable "ssh_public_key_path" {
  default = "~/.ssh/id_rsa.pub"
}

