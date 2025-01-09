terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  token     = var.token
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
}

resource "yandex_compute_disk" "boot-disk" {
  name      = "boot-disk"
  type      = "network-hdd"
  zone      = "ru-central1-a"
  size      = "20"
  image_id  = "fd8qd2nj4ghj3f72hj83"
}

resource "yandex_compute_instance" "linux-vm" {
  name        = "linux-vm"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"

  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    disk_id = yandex_compute_disk.boot-disk.id
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
  }

  metadata = {
    user-data = <<EOF
#cloud-config
users:
  - name: devops
    groups: sudo
    shell: /bin/bash
    sudo: 'ALL=(ALL) NOPASSWD:ALL'
    ssh-authorized-keys:
      - ${file("~/.ssh/id_rsa.pub")}
EOF
  }
}

resource "yandex_vpc_network" "network-1" {
  name = "network1"
}

resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet1"
  zone           = "ru-central1-a"
  v4_cidr_blocks = ["192.168.10.0/24"]
  network_id     = yandex_vpc_network.network-1.id
}
