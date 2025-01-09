
terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  # token     = "<YOUR_YC_TOKEN>"
  # cloud_id  = "<YOUR_CLOUD_ID>"
  # folder_id = "<YOUR_FOLDER_ID>"
  zone      = "ru-central1-a"
}


