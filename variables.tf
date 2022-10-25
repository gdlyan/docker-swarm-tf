variable "token" {
  description = "echo $TF_VAR_token (env varriable should be exported in advance) or set in terraform.tfvars"
  type        = string
}

variable "cloud_id" {
  description = "Yandex cloud id from yc config list"
  type        = string
}

variable "folder_id" {
  description = "Yandex folder id from yc config list"
  type        = string
}

variable "default_user" {
  type        = string
  default     = "ubuntu"
}

variable "private_key_file" {
  type        = string
  default     = "id_rsa"
}

variable "yc_zones_list" {
  description = "list of yc zones"
  type        = list(string)
  default     = ["ru-central1-a", "ru-central1-b", "ru-central1-c"]
}

variable "yc_v4_CIDR_list"{
  description = "list of CIDR for subnets"
  type        = list(list(string))
  default     = [["10.128.0.0/24"],["10.129.0.0/24"],["10.130.0.0/24"]]
}

variable "node" {
 description = "node is a manager or a worker"
 type = list(object({role = string, subnet_ix = number }))
 default = [{"role":"managers", "subnet_ix" : 0},
            {"role":"workers" , "subnet_ix" : 1},
            {"role":"workers" , "subnet_ix" : 2}]
}

variable "vpc_name" {
 type = string
 default = "docker-swarm-vpc-tf"
}



