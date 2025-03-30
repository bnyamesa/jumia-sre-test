variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_username" {
  description = "Database username"
  type        = string
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
}

variable "vpc_security_group_ids" {
  description = "List of VPC security group IDs"
  type        = list(string)
}

variable "db_subnet_group_name" {
  description = "Name of the DB Subnet Group"
  type        = string
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
}

resource "aws_db_instance" "postgres_db" {
  identifier           = "${var.project_name}-db"
  engine               = "postgres"
  engine_version       = "13"
  instance_class       = var.db_instance_class
  allocated_storage    = 20
  storage_type         = "gp2"
  username             = var.db_username
  password             = var.db_password
  db_name              = var.db_name
  db_subnet_group_name = var.db_subnet_group_name
  vpc_security_group_ids = var.vpc_security_group_ids
  skip_final_snapshot  = true
  publicly_accessible  = false
  multi_az             = false

  tags = {
    Name = "${var.project_name}-postgres-db"
  }
}

output "rds_endpoint" {
  description = "The endpoint of the RDS instance"
  value       = aws_db_instance.postgres_db.endpoint
}

output "rds_db_name" {
  description = "The name of the database"
  value       = aws_db_instance.postgres_db.db_name
}
