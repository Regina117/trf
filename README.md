# terraform
для установки на сервере
unzip terraform_1.7.0_linux_amd64.zip

зеркало яндекс:
nano ~/.terraformrc

provider_installation {
  network_mirror {
    url = "https://terraform-mirror.yandexcloud.net/"
    include = ["registry.terraform.io/*/*"]
  }
  direct {
    exclude = ["registry.terraform.io/*/*"]
  }
}

cp terraform /bin

command:
terraform init — подгружает провайдера
terraform plan — что будет изменено
terraform plan -out config.tfplan — делает версию playbook
terraform apply
terraform show
terraform destroy — удаление