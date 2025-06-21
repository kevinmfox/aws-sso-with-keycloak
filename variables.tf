variable "aws_region" {
  description = "AWS region to deploy resources in (e.g. us-east-1)"
  type        = string
}

variable "availability_zone" {
  description = "Availability zone of the subnet (e.g. us-east-1a)"
  type        = string
}

variable "dns_zone" {
  description = "The DNS zone to be used (e.g. example.com)"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC (e.g. 10.0.0.0/16)"
  type        = string
}

variable "subnet_cidr" {
  description = "CIDR block for the public subnet (10.0.0.0/24)"
  type        = string
}

variable "ami_id" {
  description = "AMI ID to use for Keycloak server"
  type        = string
}

variable "server_name" {
  description = "The name of the server - will be used for DNS and AWS tagging"
  type        = string
}

variable "instance_type" {
  description   = "Size of the AWS instance (e.g. t2.small)"
  type          = string
}

variable "instance_key" {
  description   = "SSH Key to be used for the instance"
  type          = string
}

variable "keycloak_private_ip" {
  description = "Private IP address to assign to the Keycloak server (e.g. 10.0.0.15)"
  type        = string
}

variable "certbot_staging" {
  description = "Whether or not to use staging mode for Certbot"
  type = bool
}

variable "certbot_email" {
  description = "The email address to use for cerbot SSL registration (e.g. you@example.com)"
  type = string
}
