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
  zone      = "ru-central1-c"
}

resource "yandex_vpc_network" "default" {
  name = "default-network"
}
resource "yandex_vpc_subnet" "default" {
  name           = "default-subnet"
  zone           = "ru-central1-c"
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
  zone        = "ru-central1-c"

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
  zone        = "ru-central1-c"

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
