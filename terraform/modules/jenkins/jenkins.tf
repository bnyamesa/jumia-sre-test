variable "project_name" { type = string }
variable "instance_type" { type = string }
variable "key_name" { type = string }
variable "subnet_id" { type = string }
variable "vpc_security_group_ids" { type = list(string) }

resource "aws_instance" "jenkins" {
  ami                   = var.ami_id  # Use the same AMI as microservice, or a Jenkins-specific one if available
  instance_type         = var.instance_type
  key_name              = var.key_name
  subnet_id             = var.subnet_id
  vpc_security_group_ids = var.vpc_security_group_ids

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install -y openjdk-11-jdk wget
              wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
              sudo sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
              sudo apt-get update -y
              sudo apt-get install -y jenkins
              sudo systemctl start jenkins
              EOF

  tags = { Name = "${var.project_name}-jenkins" }
}

output "jenkins_public_ip" {
  value = aws_instance.jenkins.public_ip
}
