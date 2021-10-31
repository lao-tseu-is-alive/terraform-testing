variable "infomaniak_user_name" { type = string }
variable "infomaniak_password" { type = string }
variable "infomaniak_tenant_name" { type = string }
variable "infomaniak_auth_url" { type = string }
variable "infomaniak_image_id" { type = string }
variable "infomaniak_flavor_id" { type = string }
variable "infomaniak_region" { type = string }


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
    from_port   = 443
    to_port     = 443
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
}

# Create a VM on OpenStack
# https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/resources/compute_instance_v2
resource "openstack_compute_instance_v2" "goeland-test-server" {
  name = "infomaniak-vm-goeland-test-server"
  ##  use one of : openstack image list
  image_id = var.infomaniak_image_id
  ## use one of : openstack flavor list
  flavor_id = var.infomaniak_flavor_id
  key_pair = "mykeypair"
  security_groups = ["default", "goeland_secgroup"]
  metadata = {
      gostatus= "test"
  }
  network {
      name =  "ext-net1"
  }
}

