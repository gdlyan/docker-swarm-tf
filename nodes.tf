data "yandex_compute_image" "ubuntu_image" {
  family = "ubuntu-1804-lts"
}


 

resource "yandex_compute_instance" "nodes_ubuntu_tf" {
  count = length(var.node)
  name = "${var.node[count.index].role}-node-ubuntu-tf-${yandex_vpc_subnet.subnets[var.node[count.index].subnet_ix].zone}-id${count.index}"
  zone = yandex_vpc_subnet.subnets[var.node[count.index].subnet_ix].zone
 # name = "${var.node[count.index].role}-node-ubuntu-tf-${yandex_vpc_subnet.subnets[0].zone}-id${count.index}"
 # zone = yandex_vpc_subnet.subnets[0].zone

  labels = { 
    ansible_group = "${var.node[count.index].role}"
  }

  resources {
      cores  = 2
      core_fraction = 20
      memory = 1
  }

  scheduling_policy {
      preemptible  = true
  }

  boot_disk {
      initialize_params {
          image_id = data.yandex_compute_image.ubuntu_image.id
          size = 10
      }
  }

  network_interface {
      subnet_id       = yandex_vpc_subnet.subnets[var.node[count.index].subnet_ix].id
      nat             = true
  }

  metadata = {
      user-data = <<-EOT
        #cloud-config
        ssh_pwauth: no

        groups:
          - docker

        system_info:
          default_user:
            name: ${var.default_user}
            sudo: ALL=(ALL) NOPASSWD:ALL
            groups: [docker]


        users:
          - default
          - name: ${var.default_user}
            sudo: ALL=(ALL) NOPASSWD:ALL
            shell: /bin/bash
            groups: [docker]
            ssh_authorized_keys:
              - ${file("~/.ssh/${var.private_key_file}.pub")}

        apt:
          sources:
            docker.list:
              source: deb [arch=amd64] https://download.docker.com/linux/ubuntu $RELEASE stable
              keyid: 9DC858229FC7DD38854AE2D88D81803C0EBFCD88

        packages:
          - docker-ce
          - docker-ce-cli
          - docker-compose
        EOT
  }
  
}

resource "local_file" "ansible_inventory" {
  content = yamlencode({
      "all" : {
        "children" : {
         for ansible_group in distinct(var.node.*.role):
         "${ansible_group}" => {
            "hosts" :  {
              for r in yandex_compute_instance.nodes_ubuntu_tf:
              "${r.name}" => {
                    "ansible_host" : r.network_interface.0.nat_ip_address 
                    "private_ip"  : r.network_interface.0.ip_address
                    "ansible_user" : var.default_user
                    "ansible_ssh_private_key_file" : "/root/.ssh/${var.private_key_file}"             
              }
              if r.labels.ansible_group == ansible_group 
            }
         }
        }
      }
    })              
  filename = "${path.module}/ansible/inventory_auto"
}
       