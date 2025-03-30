variable "db_name" { type = string }
variable "db_username" { type = string }
variable "db_password" { type = string }
variable "db_instance_class" { type = string }
variable "vpc_security_group_ids" { type = list(string) }
variable "db_subnet_group_name" { type = string }
variable "project_name" { type = string }

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
  tags = { Name = "${var.project_name}-postgres-db" }
}

output "rds_endpoint" {
  value = aws_db_instance.postgres_db.endpoint
}
output "rds_db_name" {
  value = aws_db_instance.postgres_db.db_name
}
