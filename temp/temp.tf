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
  zone      = "ru-central1-d"
}

data "yandex_compute_image" "ubuntu_image" {
  family = "ubuntu-2004-lts"
}
 
resource "yandex_compute_instance" "vm-test1" {
  name = "test1"
 
  resources {
    cores  = 2
    memory = 2
  }
 
  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_image.id
    }
  }
 
  network_interface {
    subnet_id = "default-ru-central1-d"
    nat       = true
  }
 
  metadata = {
    user-data = "regina:ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIBb3GHLLen70A0nwelg/oTdfw0P2bRGVAtMEwbhOBwQ"
  }
 
}
 
resource "yandex_vpc_network" "network_terraform" {
  name = "net_terraform"
}
 
resource "yandex_vpc_subnet" "default" {
  name           = "sub_terraform"
  zone           = "ru-central1-d"
  network_id     = "default-ru-central1-d"
  v4_cidr_blocks = ["10.0.0.0/24"]
}
