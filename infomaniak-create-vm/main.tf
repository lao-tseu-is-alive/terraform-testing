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

# Create a web server
resource "openstack_compute_instance_v2" "test-server" {
  name = "infomaniak-vm-test"
  image_id = var.infomaniak_image_id
  flavor_id = var.infomaniak_flavor_id
  key_pair = "mykeypair"
  metadata = {
      gostatus= "test"
  }
  network {
      name =  "ext-net1"
  }
}