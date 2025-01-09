terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  token     = "5700548b-50c4-4dd7-85f1-8c07fa3cd741"
  folder_id = "fv4ocu0l6jfp4rtn77ov"
  zone      = "ru-central1-d"
}

resource "yandex_vpc_network" "default" {
  name = "default-network"
}
resource "yandex_vpc_subnet" "default" {
  name           = "default-subnet"
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.default.id
  v4_cidr_blocks = ["10.0.0.0/24"]
}

resource "yandex_storage_bucket" "repo_bucket" {
  bucket = "java-app-repo"

  acl = "private"

  lifecycle_rule {
    enabled = true
    expiration {
      days = 30
    }
  }
}

# build instance
resource "yandex_compute_instance" "build_instance" {
  name        = "build-instance"
  platform_id = "standard-v1"
  zone        = "ru-central1-d"

  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = "fv4ocu0l6jfp4rtn77ov" 
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.default.id
    nat       = true
  }

  metadata = {
    ssh-keys = "regina:ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIBb3GHLLen70A0nwelg/oTdfw0P2bRGVAtMEwbhOBwQ"
    user-data = <<EOF
datasource:
 Ec2:
  strict_id: false
ssh_pwauth: no
users:
- name: regina
  sudo: ALL=(ALL) NOPASSWD:ALL
  shell: /bin/bash
  ssh_authorized_keys:
  - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIBb3GHLLen70A0nwelg/oTdfw0P2bRGVAtMEwbhOBwQ
packages:
  - git
  - openjdk-11-jdk
  - maven
  - awscli
runcmd:
  - git clone https://github.com/geoserver/geoserver.git /app
  - cd /app/src
  - mvn clean package -DskipTests
  - /bin/bash -c "aws s3 cp /app/src/web/app/target/geoserver.war s3://java-app-repo/geoserver.war --region ru-central1"
EOF
  }
}

# prod instance
resource "yandex_compute_instance" "prod_instance" {
  name        = "prod-instance"
  platform_id = "standard-v1"
  zone        = "ru-central1-d"

  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = "fv4ocu0l6jfp4rtn77ov" 
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.default.id
    nat       = true
  }

  metadata = {
    ssh-keys = "regina:ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIBb3GHLLen70A0nwelg/oTdfw0P2bRGVAtMEwbhOBwQ"
    user-data = <<EOF
datasource:
 Ec2:
  strict_id: false
ssh_pwauth: no
users:
- name: regina
  sudo: ALL=(ALL) NOPASSWD:ALL
  shell: /bin/bash
  ssh_authorized_keys:
  - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIBb3GHLLen70A0nwelg/oTdfw0P2bRGVAtMEwbhOBwQ
packages:
  - tomcat9
  - awscli
runcmd:
  - /bin/bash -c "aws s3 cp s3://java-app-repo/geoserver.war /tmp/geoserver.war --region ru-central1"
  - cp /tmp/geoserver.war /var/lib/tomcat9/webapps/geoserver.war
  - systemctl restart tomcat9
EOF
  }
}

output "build_instance_ip" {
  value = yandex_compute_instance.build_instance.network_interface.0.nat_ip_address
}

output "prod_instance_ip" {
  value = yandex_compute_instance.prod_instance.network_interface.0.nat_ip_address
}
