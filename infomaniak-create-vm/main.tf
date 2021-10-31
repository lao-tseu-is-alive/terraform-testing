## simple example to create a VM on Infomaniak Openstack Cloud with terraform
## terraform plan -var-file="infomaniak.tfvars"
## terraform apply -var-file="infomaniak.tfvars"
## terraform show 
## will give you :
## # openstack_compute_instance_v2.goeland-test-server:
## resource "openstack_compute_instance_v2" "goeland-test-server" {
##    access_ip_v4        = "195.15.240.160"
## ...
## connect to it with ssh :
## ssh ubunutu@195.15.240.160
## when you are finish using your VM just clean your stuff and destroy everything
##  terraform destroy -var-file="infomaniak.tfvars"
variable "infomaniak_user_name" { type = string }
variable "infomaniak_password" { type = string }
variable "infomaniak_tenant_name" { type = string }
variable "infomaniak_auth_url" { type = string }
variable "infomaniak_image_id" { type = string }
variable "infomaniak_flavor_id" { type = string }
variable "infomaniak_region" { type = string }

variable "ssh_pub_key_file" {
  type    = string
  default = "~/.ssh/id_ecdsa.pub"
}

variable "ssh_private_key_file" {
  type    = string
  default = "~/.ssh/id_ecdsa"
}

variable "ssh_user_name" {
  type    = string
  default = "ubuntu"
}


# Define required providers
terraform {
  required_version = ">= 0.14.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.35.0"
    }
  }
}

# Configure the OpenStack Provider
provider "openstack" {
  user_name   = var.infomaniak_user_name
  tenant_name = var.infomaniak_tenant_name
  password    = var.infomaniak_password
  auth_url    = var.infomaniak_auth_url
  region      = var.infomaniak_region
}

# https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/resources/compute_secgroup_v2
resource "openstack_compute_secgroup_v2" "secgroup_goeland1" {
  name        = "goeland_secgroup"
  description = "my security group to allow ssh and https access"

  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = 80
    to_port     = 80
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = 443
    to_port     = 443
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
}

# Create a VM on OpenStack
# https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/resources/compute_instance_v2
resource "openstack_compute_instance_v2" "goeland-test-server" {
  depends_on = [
    openstack_compute_secgroup_v2.secgroup_goeland1
  ]
  name = "infomaniak-vm-goeland-test-server"
  ##  use one of : openstack image list
  image_id = var.infomaniak_image_id
  ## use one of : openstack flavor list
  flavor_id = var.infomaniak_flavor_id
  # optional use one of : openstack availability zone list
  # availability_zone = "dc3-a-04"
  key_pair        = "mykeypair"
  security_groups = ["default", "goeland_secgroup"]
  metadata = {
    gostatus = "test"
  }
  network {
    name = "ext-net1"
  }
}

resource "null_resource" "provision" {
  depends_on = [
    openstack_compute_instance_v2.goeland-test-server
  ]
  connection {
    user        = var.ssh_user_name
    private_key = file(var.ssh_private_key_file)
    host        = openstack_compute_instance_v2.goeland-test-server.access_ip_v4
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get -y update",      
      "sudo apt-get -y install certbot python3-certbot-nginx",
      "sudo apt-get -y dist-upgrade",
      "sudo service nginx start",
      "echo \"alias lsa='ls -al -tr'\" >> /home/ubuntu/.bashrc"
    ]
  }

}


output "access_ip_v4" {
  value = openstack_compute_instance_v2.goeland-test-server.access_ip_v4
}
