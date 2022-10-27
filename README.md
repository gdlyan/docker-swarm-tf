# docker-swarm-tf
Terraform &amp; Ansible config for arbitrary web application deployment on a Swarm cluster @ Yandex Cloud 

## Use case
The purpose of this configuration is to ease the learning curve of a full-stack developer who just ramps up with IaC (Infrastructure as Code) 
- Familiarize oneself with Swarm by spawning a low-scale hence low-cost toy cluster on Yandex Cloud with as little prerequsites and effort as possible (literally two `docker run` shell commands that can be further combined into a pipeline)
- Test containered web apps in Swarm and observe their behavior at scale
- Use the configuration as a source of snippets to copy-paste from   

## Requirements
- Linux / MacOS / Windows with WSL2 machine connected to Internet
- Docker and optionally Compose
- A pair of ssh keys whereas a public key would be uploaded to the provisioned virtual machines. Please note that the current config fails with passphrase protected keys, so if your default ssh key pair is passphrase protected please be sure to generate a dedicated key pair. 
- Yandex Cloud account that has a payment method activated [see how-to](https://cloud.yandex.com/en-ru/docs/billing/operations/create-new-account)
- Yandex cloud CLI installed with `curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash` and initialized with `yc init` as explained in the [Getting started with the YC CLI manual](https://cloud.yandex.com/en-ru/docs/cli/quickstart). 
- You will need to create a file `./terraform.tfvars` with the following content:
```
token             = "<Yandex Cloud OAuth token, available from `yc config list` command>"
cloud_id          = "<ID of the cloud where the VPC would be spawned, available from `yc config list` command"
folder_id         = "<ID of the folder where the VPC would be spawned, available from `yc config list` command>"
default_user      = "non-root user to be created on the target VMs, defaulted to `ubuntu`"
private_key_file  = "not passphrase-encrypted private key file located in `~./ssh` directory, defaulted to `id_rsa`"
```

## Directory content
- `./app/` A container web app that implements a very simple function of hit count and is tested on a stand-alone machine such as localhost - here we use the same one as in [Deploy a stack to a swarm](https://docs.docker.com/engine/swarm/stack-deploy/) tutorial
- `./` Terraform config to provision a basic YC virtual private cloud with three subnets and a number of preemptible virtual machines serving as manager or woker nodes in the Swarm cluster
- `ansible/` Ansible playbook to bootstrap a swarm, i.e. initialize swarm, assign the 'manager' and 'worker' roles among the nodes and deploys a web app to a swarm 
- `./dterraform` and `dansible-playbook` shell files that spawn containers from Terraform and Ansible images on docker hub. Thus one does not have to install Terraform and Ansible locally as these Docker wrappers will do the job 

## Basic usage
### 1. On a first run execute
```
./dterraform init
```
This will pull terraform docker image, spawn the terraform container and install the required terraform providers
### 2. To create infrastructure such as VPC, subnets, VMs and their network interfaces run
```
./dterraform apply -auto-approve
```
This will create a network and three subnets. In each of those subnets a low-tier Ubuntu VM will be spawned with Docker and Compose installed. Each VM will be assigned with a dynamic public IP and be accessible via `ssh -i ~/.ssh/<private_key_file> <default_user>@<public IP>`. 

Also this command will create an __Ansible inventory__ file  `./ansible/iventory_auto`. It's purpose is to link the VMs to their roles in swarm: one of the nodes will further become a manager, others - workers. As the IP are assigned to VMs dynamically we may not be aware of the nodes' network addresses before the VMs are actually created, hence we generate inventory in a dynamic manner either.

The successful output would look like similar to the  following one:
```
Apply complete! Resources: 8 added, 0 changed, 0 destroyed.

Outputs:

resource_public_api = [
  <<-EOT
  - "managers-node-ubuntu-tf-ru-central1-a-id0":
      "private_ip": "10.<internal IP 1>"
      "public_ip": "<public IP 1>"
      "ssh_command": "ssh -i ~/.ssh/<private_key_file> <default_user>@<public IP 1>"
  - "workers-node-ubuntu-tf-ru-central1-b-id1":
      "private_ip": "10.129.0.9"
      "public_ip": "158.160.17.232"
      "ssh_command": "ssh -i ~/.ssh/<private_key_file> <default_user>@<public IP 2>"
  - "workers-node-ubuntu-tf-ru-central1-c-id2":
      "private_ip": "10.130.0.20"
      "public_ip": "51.250.33.215"
      "ssh_command": "ssh -i ~/.ssh/<private_key_file> <default_user>@<public IP 2>"

  EOT,
  "For swarm initialization run the command: './dansible-playbook -i inventory_auto playbook.yml'",
]
```
> *Note that since this very moment the platform starts charging you for the provisioned infrastructure. The amount should not be dramatic as the VMs are provisioned preemptible and at minimal configuration. Still be sure to destroy the infrastructure when you figure out you no longer need it for your experiments (see the last step with `./dterraform destroy -auto-approve` command).*
### 3. To run the Ansible play that initializes the Swarm, attaches the worker nodes to the manager node and launchs a container try:
```
./dansible-playbook -i inventory_auto playbook.yml
```
Wait for a couple of minutes for bootstraping routine to complete. The successful output would look lke the following one (the non-zero numbers next to "ok" and "changed" might be different):
```
PLAY RECAP *************************************************************************************************************
managers-node-ubuntu-tf-ru-central1-a-id0 : ok=13   changed=10   unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
workers-node-ubuntu-tf-ru-central1-b-id1 : ok=4    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
workers-node-ubuntu-tf-ru-central1-c-id2 : ok=4    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```
> You may observe the word "Failed" in the Ansible log stream during the play runtime. Please don't be confused with that - it just means that Ansible checks if Docker is up and running, but Docker installation is still in progress. If this is the case Ansible will retry the test until `docker info` returns something meaningful on the target end 
### 4. Now it is time to test that the swarm is working!
- Run `./dterraform output` to view once again the public IP of the provisioned virtual machines
- Ssh into the manager node using `ssh -i ~/.ssh/<private_key_file> <default_user>@<public IP 1>` then run the command `docker node ls`. The output similar to the following would prove that the swarm is up and running:
```
ID                            HOSTNAME               STATUS    AVAILABILITY   MANAGER STATUS   ENGINE VERSION
zae08kw0iwu3o2k7ci8jhlpe3     ef31ct15mo4clggqm1h5   Ready     Active                          20.10.21
yqa8l20ggar9wvmi9cyaxgdgo     epd1obu2jqldaq3dv7q3   Ready     Active                          20.10.21
uqv71jz9cm45fwc0g02hxhm0w *   fhmsftna4v32q2c7aues   Ready     Active         Leader           20.10.21
```
- In the browser for each of the machine try the URL `http://<public IP>:8000`. Regardless of the IP being called the outcome would look like `Hello World! I have been seen X times.` where X adds up every time we hit any of the machine in the cluster.
- Ssh into each machine in the swarm and run `docker ps`. You would likely see that the containers are spread across the swarm. The app container would run on one node, the redis container on a different one, and there will be no single node that runs all both containers together.   
> This is the very basic demonstration of Swarm Routing Mesh. The application behavior would be similar on every endpoint exposed to the outer world. Under the hood the containers are distributed across the Swarm nodes while Swarm take care of combining them together. More information on Swarn Routing Mesh is available in [Docker tutorials](https://docs.docker.com/engine/swarm/ingress/)  


