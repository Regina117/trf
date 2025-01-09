terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  token     = "y0__wgBENPV_IUCGMHdEyCis4b-EZr_VyNwznnybCcPlXNywg3E7sZf"
  cloud_id  = "b1gmclt461srvopvr7i7"
  folder_id = "b1g877q94b2773okudu0"
}

resource "yandex_compute_disk" "boot-disk" {
  name = "boot-disk"
  type = "network-hdd"
  zone = "ru-central1-a"
  size = "20"
  image_id = "fd895e9j3al6len7lg24" 
}
resource "yandex_compute_instance" "linux-vm" {
  name = "linux-vm"
  platform_id = "standard-v3"
  zone = "ru-central1-a"
resources {
  cores = 2
  memory = 4
}
boot_disk {
  disk_id = yandex_compute_disk.boot-disk.id
}
network_interface {
  subnet_id = yandex_vpc_subnet.subnet-1.id
  nat = true
}
metadata = {
  user-data = "#cloud-config\nusers:\n - name: devops\n groups: sudo\n shell: /bin/bash\n sudo: 'ALL=(ALL) NOPASSWD:ALL'\n ssh-authorized-keys:\n - ${file("~/.ssh/id_rsa.pub")}"
}
}
resource "yandex_vpc_network" "network-1" {
  name = "network1"
}
resource "yandex_vpc_subnet" "subnet-1" {
  name = "subnet1"
  zone = "ru-central1-a"
  v4_cidr_blocks = ["192.168.10.0/24"]
  network_id = yandex_vpc_network.network-1.id
}
