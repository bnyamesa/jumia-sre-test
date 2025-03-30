terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = var.aws_region
}

# --- Networking ---
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

resource "aws_subnet" "public" {
  count                  = length(var.public_subnet_cidrs)
  vpc_id                 = aws_vpc.main.id
  cidr_block             = var.public_subnet_cidrs[count.index]
  availability_zone      = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet-${count.index + 1}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# --- Security Groups ---

resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-alb-sg"
  description = "Allow HTTP traffic to ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "${var.project_name}-rds-sg"
  description = "Allow PostgreSQL traffic from microservice"  # DO NOT change this value!
  vpc_id      = aws_vpc.main.id

  lifecycle {
    ignore_changes = [
      description,
      ingress,  # Ignore changes to the ingress blocks to prevent replacement
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-rds-sg"
  }
}

resource "aws_security_group" "microservice_sg" {
  name        = "jumia-sre-challenge-microservice-sg"
  description = "Allow SSH, and traffic from ALB"
  vpc_id      = aws_vpc.main.id

  lifecycle {
    ignore_changes = [
      description,
    ]
  }

  ingress {
    description = "SSH on custom port 1337"
    from_port   = 1337
    to_port     = 1337
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description     = "HTTP from ALB to Frontend"
    from_port       = 8081
    to_port         = 8081
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    description     = "HTTP from ALB for Backend"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jumia-sre-challenge-microservice-sg"
  }
}

resource "aws_security_group_rule" "rds_ingress_from_microservice" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds_sg.id
  source_security_group_id = aws_security_group.microservice_sg.id
  description              = "Allow PostgreSQL traffic from Microservice SG"
}

resource "aws_security_group_rule" "rds_ingress_from_vpc" {
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  security_group_id = aws_security_group.rds_sg.id
  cidr_blocks       = [var.vpc_cidr]
  description       = "Allow PostgreSQL traffic from the entire VPC"
}

# --- RDS Subnet Group ---
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = aws_subnet.public[*].id

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# --- EC2 Instance for Microservice ---
resource "aws_instance" "microservice" {
  ami                   = var.ami_id
  instance_type         = var.instance_type
  key_name              = var.ssh_key_name
  subnet_id             = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.microservice_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    sudo apt-get update -y
    sudo apt-get install -y python3 python3-pip python3-venv ufw || true
    sudo systemctl stop ufw || true
    sudo systemctl disable ufw || true
    sudo ufw disable || true
    echo "Install python done"
  EOF

  tags = {
    Name = "${var.project_name}-microservice-instance"
  }
}

# --- RDS Module ---
module "rds" {
  source                 = "./modules/rds"
  db_name                = var.db_name
  db_username            = var.db_username
  db_password            = var.db_password
  db_instance_class      = var.db_instance_class
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  project_name           = var.project_name
  depends_on             = [aws_db_subnet_group.db_subnet_group]
}

# --- ALB Module ---
module "elb" {
  source             = "./modules/elb"
  project_name       = var.project_name
  vpc_id             = aws_vpc.main.id
  subnet_ids         = aws_subnet.public[*].id
  security_groups    = [aws_security_group.alb_sg.id]
  target_instance_id = aws_instance.microservice.id
  depends_on         = [aws_instance.microservice]
}

# --- EKS Module ---
module "eks" {
  source        = "./modules/eks"
  project_name  = var.project_name
  subnet_ids    = aws_subnet.public[*].id
  instance_type = var.instance_type
}

# --- Jenkins Module ---
module "jenkins" {
  source        = "./modules/jenkins"
  project_name  = var.project_name
  ami_id        = var.ami_id
  instance_type = var.instance_type
  ssh_key_name  = var.ssh_key_name
  vpc_id        = aws_vpc.main.id
  subnet_ids    = aws_subnet.public[*].id
}
