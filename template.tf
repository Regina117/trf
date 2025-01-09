provider "yandex" {
  token     = "y0__wgBENPV_IUCGMHdEyCis4b-EZr_VyNwznnybCcPlXNywg3E7sZf"
  cloud_id  = "b1gmclt461srvopvr7i7"
  folder_id = "b1g877q94b2773okudu0"
  zone      = "ru-central1-d"
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
variable "new1" {
  default = "new1"
}
variable "vm_cores" {
  default = 2
}
variable "vm_memory" {
  default = 4  # в ГБ
}
variable "image_id" {
  default = "fd895e9j3al6len7lg24"  
}
variable "ssh_public_key_path" {
  default = "~/.ssh/id_rsa.pub"
}
