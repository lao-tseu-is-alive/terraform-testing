variable "exoscale_api_key" { type = string }
variable "exoscale_api_secret" { type = string }

/****************************************************************
how to create a simple vm on exoscale with terraform:
  1) no need to prior login with exo cli, just have a IAM key/secret
  2) cd in this directory and then the classic init/plan/apply
  3) terraform init
  4) terraform plan
  5) terraform apply
  6) terraform show
  7) and if you want to cleanup everything : terraform destroy
 
 to connect to the VM use the allocated ip from step 6: ssh ubuntu@194.182.163.23
 you may need to create a FW rule to allow incoming ssh trafic
 just go the exo web console --> compute/firewalling  and add a rule like :

  INGRESS TCP CIDR YOUR_IP/32 TCP 22 - 22

  or just click on the SSH button on the upper-right but be carefull 
  because you will then allow every single ip on he "universe" to come in...

 more information :
 https://registry.terraform.io/providers/exoscale/exoscale/latest/docs/resources/compute
****************************************************************/

terraform {
  required_providers {
    exoscale = {
      source  = "exoscale/exoscale"
      version = "0.18.2"
    }
  }
}

provider "exoscale" {
  key    = var.exoscale_api_key
  secret = var.exoscale_api_secret
}

locals {
  zone = "ch-gva-2"
}

data "exoscale_compute_template" "ubuntu" {
  zone = local.zone
  name = "Linux Ubuntu 20.04 LTS 64-bit"
}

resource "exoscale_compute" "goeland_server" {
  zone         = local.zone
  display_name = "goeland-server"
  size         = "Small"
  template_id  = data.exoscale_compute_template.ubuntu.id
  disk_size    = 50
  security_groups = ["allow_ssh_to_vdl"]
  key_pair     = "cgil@vortex"
  user_data    = <<EOF
#cloud-config
package_upgrade: true
EOF

tags = {
    production = "true"
    resource = "goeland"
  }

  timeouts {
    create = "60m"
    delete = "2h"
  }

}

output "instance_ip_addr" {
  description = "ip address of vm"
  value = exoscale_compute.goeland_server.ip_address
}

output "ssh_connexion" {
  description = "ssh command to connect to the vm"
  value = "ssh ${data.exoscale_compute_template.ubuntu.username}@${exoscale_compute.goeland_server.ip_address}"
}
