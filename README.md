# docker-swarm-tf
Terraform &amp; Ansible config for arbitrary web application deployment on a Swarm cluster @ Yandex Cloud 

## Use case
The purpose of this configuration is to ease the learning curve of a full-stack developer who just ramps up with IaaC 
- Familiarize oneself with Swarm by spawning a low-scale hence low-cost toy cluster on Yandex Cloud with as little prerequsites and effort as possible (literally two clicks that can be further combined into a pipeline)
- Test containered web apps in Swarm and observe their behavior at scale
- Use the configuration as a source of snippets to copy-paste from   

## Requirements
- Linux / MacOS / Windows with WSL2 machine connected to Internet
- Docker and optionally Compose
- A pair of ssh keys whereas a public key would be uploaded to the provisioned virtual machines. Please note that the current config fails with passphrase protected keys, so it is recommended to generate a dedicated pair of ssh-keys for this use case. 
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
- On a first run execute
```
./dterraform init
```
- To create infrastructure such as VPC, subnets, VMs and their network interfaces run
```
./dterraform apply -auto-approve
```
