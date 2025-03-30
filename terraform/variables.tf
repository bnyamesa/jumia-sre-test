variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  description = "A name for the project to tag resources"
  type        = string
  default     = "jumia-sre-challenge"
}

variable "ami_id" {
  description = "AMI ID for EC2 instances (Ubuntu in eu-central-1)"
  type        = string
  default     = "ami-04a5bacc58328233d"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ssh_key_name" {
  description = "Name of the SSH key pair registered in AWS"
  type        = string
  default     = "jumia_devops"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "jumia_phone_validator"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "jumia"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
  default     = "Cherotich12!"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "availability_zones" {
  description = "Availability zones to use"
  type        = list(string)
  default     = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
}

variable "db_subnet_group_name" {
  description = "Name of the RDS DB Subnet Group"
  type        = string
  default     = "jumia-sre-challenge-db-subnet-group"
}

# EKS Cluster variables (Bonus)
variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "jumia-sre-challenge-eks"
}

variable "desired_capacity" {
  description = "Desired capacity for the EKS node group"
  type        = number
  default     = 3
}

variable "min_capacity" {
  description = "Minimum capacity for the EKS node group"
  type        = number
  default     = 3
}

variable "max_capacity" {
  description = "Maximum capacity for the EKS node group"
  type        = number
  default     = 3
}
