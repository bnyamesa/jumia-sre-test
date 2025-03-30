output "microservice_instance_public_ip" {
  description = "Public IP address of the Microservice EC2 instance"
  value       = aws_instance.microservice.public_ip
}

output "microservice_instance_id" {
  description = "ID of the Microservice EC2 instance"
  value       = aws_instance.microservice.id
}

output "rds_endpoint" {
  description = "Endpoint of the RDS PostgreSQL database"
  value       = module.rds.rds_endpoint
}

output "rds_db_name" {
  description = "Name of the RDS Database"
  value       = module.rds.rds_db_name
}

output "alb_dns_name" {
  description = "DNS Name of the Application Load Balancer"
  value       = module.elb.alb_dns_name
}

output "alb_target_group_arn" {
  description = "ARN of the ALB Target Group"
  value       = module.elb.target_group_frontend_arn
}

output "ansible_inventory" {
  description = "Pre-formatted entry for Ansible inventory"
  value       = <<-EOT
    [microservice]
    ${aws_instance.microservice.public_ip} ansible_host=${aws_instance.microservice.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/jumia_devops ansible_ssh_port=1337
  EOT
  sensitive   = false
}

output "eks_cluster_endpoint" {
  description = "Endpoint for the EKS Cluster"
  value       = module.eks.eks_cluster_endpoint
}

output "eks_cluster_name" {
  description = "Name of the EKS Cluster"
  value       = module.eks.eks_cluster_name
}

output "jenkins_instance_public_ip" {
  description = "Public IP address of the Jenkins server"
  value       = module.jenkins.jenkins_instance_public_ip
}
