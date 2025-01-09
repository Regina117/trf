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

resource "yandex_vpc_network" "default" {  
  name = "default-network"
  folder_id = "b1g877q94b2773okudu0"
}

resource "yandex_vpc_subnet" "default" {
  name           = "default-subnet"
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.default.id
  folder_id      = "b1g877q94b2773okudu0"
  v4_cidr_blocks = ["10.0.0.0/24"]
}

resource "yandex_storage_bucket" "repo_bucket" {
  bucket = "java-app-repo"
  folder_id = "b1g877q94b2773okudu0"
  acl = "private"

  lifecycle_rule {
    enabled = true
    expiration {
      days = 30
    }
  }
}

# build instance
resource "yandex_compute_instance" "build" {
  name        = "build"
  platform_id = "standard-v2"
  zone        = "ru-central1-d"

  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = "fd895e9j3al6len7lg24" 
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.default.id
    nat       = true
  }

  metadata = {
    ssh-keys = "regina:ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIBb3GHLLen70A0nwelg/oTdfw0P2bRGVAtMEwbhOBwQ"
    user-data = <<EOF
#cloud-config
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
  - yc
runcmd:
  - git clone https://github.com/geoserver/geoserver.git /app
  - echo "Git clone finished" >> /var/log/build.log
  - cd /app/src
  - mvn clean package -DskipTests >> /var/log/build.log 2>&1
  - echo "Maven build finished" >> /var/log/build.log
  - /bin/bash -c "yc storage object upload /app/src/web/app/target/geoserver.war --bucket java-app-repo --name geoserver.war" >> /var/log/build.log 2>&1
  - echo "File uploaded to storage" >> /var/log/build.log
EOF
  }
}

# prod instance
resource "yandex_compute_instance" "prod" {
  name        = "prod"
  platform_id = "standard-v2"
  zone        = "ru-central1-d"

  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = "fd895e9j3al6len7lg24" 
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.default.id
    nat       = true
  }

  metadata = {
    ssh-keys = "regina:ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIBb3GHLLen70A0nwelg/oTdfw0P2bRGVAtMEwbhOBwQ regina@dell-5430"
    user-data = <<EOF
#cloud-config
datasource:
 Ec2:
  strict_id: false
ssh_pwauth: no
users:
- name: regina
  sudo: ALL=(ALL) NOPASSWD:ALL
  shell: /bin/bash
  ssh_authorized_keys:
  - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIBb3GHLLen70A0nwelg/oTdfw0P2bRGVAtMEwbhOBwQ regina@dell-5430
packages:
  - tomcat9
  - yc
runcmd:
  - echo "Start downloading WAR file" >> /var/log/prod.log
  - /bin/bash -c "yc storage cp ys://java-app-repo/geoserver.war /tmp/geoserver.war" >> /var/log/prod.log 2>&1
  - echo "File downloaded" >> /var/log/prod.log
  - cp /tmp/geoserver.war /var/lib/tomcat9/webapps/geoserver.war
  - echo "WAR file copied to Tomcat" >> /var/log/prod.log
  - systemctl restart tomcat9 >> /var/log/prod.log 2>&1 
  - echo "Tomcat restarted" >> /var/log/prod.log
EOF
  }
}

output "build_instance_ip" {
  value = yandex_compute_instance.build.network_interface.0.ip_address
}

output "prod_instance_ip" {
  value = yandex_compute_instance.prod.network_interface.0.ip_address
}