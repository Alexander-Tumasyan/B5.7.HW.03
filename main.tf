provider "yandex" {
  token     = var.token
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = "ru-central1-a"
}

resource "yandex_vpc_network" "network" {
  name = "network"
}

resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet-1"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

resource "yandex_vpc_subnet" "subnet-2" {
  name           = "subnet-2"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = ["192.168.11.0/24"]
}

resource "yandex_lb_target_group" "my_target_group" {
  name      = "my-target-group"
  region_id = "ru-central1"

  target {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    address   = module.vm1.internal_ip_address_vm
  }

  target {
    subnet_id = yandex_vpc_subnet.subnet-2.id
    address   = module.vm2.internal_ip_address_vm
  }
}

module "vm1" {
  source                = "./modules/instance"
  instance_family_image = "lemp"
  vpc_subnet_id         = yandex_vpc_subnet.subnet-1.id
  instance_zone         = "ru-central1-a"
}

module "vm2" {
  source                = "./modules/instance"
  instance_family_image = "lamp"
  vpc_subnet_id         = yandex_vpc_subnet.subnet-2.id
  instance_zone         = "ru-central1-b"
}

module "balancer" {
  source          = "./modules/balancer"
  target_group_id = yandex_lb_target_group.my_target_group.id
}