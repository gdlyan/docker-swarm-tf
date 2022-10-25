output "resource_public_api" {
   value = [
    yamlencode([  
     for r in yandex_compute_instance.nodes_ubuntu_tf : { 
         (r.name): {
            "public_ip": r.network_interface.0.nat_ip_address
            "private_ip": r.network_interface.0.ip_address
            "ssh_command": "ssh -i ~/.ssh/${var.private_key_file} ${var.default_user}@${r.network_interface.0.nat_ip_address}"
         }
       }  
    ]),
    "For swarm initialization run the command: './dansible-playbook -i inventory_auto playbook.yml'"
   ] 
}
