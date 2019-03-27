
variable "aws_region" {
  description = "The AWS region to create things in."
  default     = "eu-west-1"
}

variable "vpc_cidr" {
  description = "Testing Terraform stuff"
  default = "172.18.0.0/24"
}

variable "ingress_subnet_az_1_CIDR" {
  description = "Ingress Subnet AZ 1 CIDR"
  default = "172.18.0.0/27"
}

variable "ingress_subnet_az_2_CIDR" {
  description = "Ingress Subnet AZ 1 CIDR"
  default = "172.18.0.32/27"
}

variable "private_subnet_az_1_CIDR" {
  description = "Ingress Subnet AZ 1 CIDR"
  default = "172.18.0.64/27"
}

variable "private_subnet_az_2_CIDR" {
  description = "Ingress Subnet AZ 1 CIDR"
  default = "172.18.0.96/27"
}

variable "bastion_sshrdp_from" {
   description = "Connect from Outside"
   default = "79.118.88.243/32"
}


