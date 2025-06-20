provider "aws" {
    region = var.aws_region
}

data "aws_route53_zone" "dns_zone" {
  name         = "${var.dns_zone}."
  private_zone = false
}

resource "aws_vpc" "keycloak_vpc" {
    cidr_block           = var.vpc_cidr_block
    enable_dns_hostnames = true
    tags = {
        Name = "keycloak-vpc"
    }
}

resource "aws_subnet" "public_subnet" {
    vpc_id                  = aws_vpc.keycloak_vpc.id
    cidr_block              = var.subnet_cidr
    map_public_ip_on_launch = true
    availability_zone       = var.availability_zone
    tags = {
        Name = "keycloak-public-subnet"
    }
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.keycloak_vpc.id
    tags = {
        Name = "keycloak-igw"
    }
}

resource "aws_route_table" "public_rt" {
    vpc_id = aws_vpc.keycloak_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }
    tags = {
        Name = "keycloak-public-rt"
    }
}

resource "aws_route_table_association" "public_assoc" {
    subnet_id      = aws_subnet.public_subnet.id
    route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "keycloak_sg" {
    name        = "keycloak-sg"
    description = "Allow SSH, HTTP, and HTTPS"
    vpc_id      = aws_vpc.keycloak_vpc.id

    ingress {
        description = "SSH"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "HTTP (Keycloak)"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "HTTP (Keycloak)"
        from_port   = 8080
        to_port     = 8080
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "HTTPS (Keycloak)"
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "keycloak_server" {
    ami                     = var.ami_id
    instance_type           = var.instance_type
    subnet_id               = aws_subnet.public_subnet.id
    private_ip              = var.keycloak_private_ip
    vpc_security_group_ids  = [aws_security_group.keycloak_sg.id]
    key_name                = var.instance_key

    tags = {
        Name = var.server_name
    }

    user_data = templatefile("${path.module}/cloud-init-keycloak.sh", {
      server_name       = var.server_name
      dns_zone          = var.dns_zone
      certbot_staging   = var.certbot_staging
      certbot_email     = var.certbot_email
    })

}

resource "aws_eip" "keycloak" {
    instance  = aws_instance.keycloak_server.id
    domain    = "vpc"
}

resource "aws_route53_record" "keycloak" {
    zone_id = data.aws_route53_zone.dns_zone.id
    name    = "${var.server_name}.${var.dns_zone}"
    type    = "A"
    ttl     = 60
    records = [aws_eip.keycloak.public_ip]
}
