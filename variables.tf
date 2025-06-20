variable "aws_region" {
  description = "AWS region to deploy resources in"
  type        = string
}

variable "availability_zone" {
  description = "Availability zone of the subnet"
  type        = string
}

variable "dns_zone" {
  description = "The DNS zone to be used"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
}

variable "ami_id" {
  description = "AMI ID to use for Keycloak server"
  type        = string
}

variable "server_name" {
  description = "The name of the server. Will be used for DNS and AWS tagging."
  type        = string
}

variable "instance_type" {
  description   = "Size of the AWS instance"
  type          = string
}

variable "instance_key" {
  description   = "SSH Key to be used for the instance"
  type          = string
}

variable "keycloak_private_ip" {
  description = "Private IP address to assign to the Keycloak server"
  type        = string
}

variable "certbot_staging" {
  description = "Whether or not to use staging mode for Certbot"
  type = bool
}

variable "certbot_email" {
  description = "The email address to use for cerbot"
  type = string
}
