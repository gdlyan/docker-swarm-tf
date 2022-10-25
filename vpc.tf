terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    } 
    local = {
      source = "hashicorp/local"
      version = "2.2.3"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  token     = var.token
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
}

resource "yandex_vpc_network" "docker_swarm_vpc_tf" {
  name = var.vpc_name
  description = "Terraform managed VPC for experiments with Swarm"
}

resource "yandex_vpc_subnet" "subnets" {
  count = length(var.yc_zones_list)
  network_id = yandex_vpc_network.docker_swarm_vpc_tf.id
  name = "${var.vpc_name}-${var.yc_zones_list[count.index]}"
  description = "Terraform managed subnet for zone ${var.yc_zones_list[count.index]} in docker-swarm-vpc-tf"
  zone = var.yc_zones_list[count.index]
  v4_cidr_blocks = var.yc_v4_CIDR_list[count.index]
}





