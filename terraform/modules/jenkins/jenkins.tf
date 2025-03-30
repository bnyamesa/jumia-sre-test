# --- File: ./terraform/modules/jenkins/jenkins.tf ---

variable "project_name" {
  description = "Project name for tagging"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for the Jenkins EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for Jenkins"
  type        = string
}

variable "ssh_key_name" {
  description = "SSH key name for the instance"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID in which to launch the Jenkins instance"
  type        = string
}

variable "subnet_ids" {
  description = "List of public subnet IDs for Jenkins"
  type        = list(string)
}

resource "aws_security_group" "jenkins_sg" {
  name        = "${var.project_name}-jenkins-sg"
  description = "Allow HTTP and SSH access for Jenkins"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTP access for Jenkins UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH access on port 1337"
    from_port   = 1337
    to_port     = 1337
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-jenkins-sg"
  }
}

resource "aws_instance" "jenkins" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = var.ssh_key_name
  # Use the first subnet in the list (index 0) to ensure a public IP is assigned
  subnet_id                   = element(var.subnet_ids, 0)
  vpc_security_group_ids      = [aws_security_group.jenkins_sg.id]
  associate_public_ip_address = true

  # Updated user_data to include UFW configuration
  user_data = <<-EOF
    #!/bin/bash
    set -e

    # Update package list and install required packages
    apt-get update -y
    # Ensure UFW is installed before configuring it
    apt-get install -y openjdk-11-jdk wget ufw

    # Add the Jenkins repository key and source list, then install Jenkins
    wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | apt-key add -
    echo "deb https://pkg.jenkins.io/debian-stable binary/" > /etc/apt/sources.list.d/jenkins.list
    apt-get update -y
    apt-get install -y jenkins

    # Ensure Jenkins listens on all interfaces
    if grep -q "^HTTP_HOST=" /etc/default/jenkins; then
      sed -i 's/^HTTP_HOST=.*/HTTP_HOST=0.0.0.0/' /etc/default/jenkins
    else
      echo "HTTP_HOST=0.0.0.0" >> /etc/default/jenkins
    fi
    # Optional: Increase Jenkins Heap Size if needed (adjust values as necessary)
    # sed -i 's/JAVA_ARGS="-Djava.awt.headless=true"/JAVA_ARGS="-Djava.awt.headless=true -Xms512m -Xmx1024m"/' /etc/default/jenkins


    # Reconfigure SSH to listen on port 1337
    if grep -q "^Port " /etc/ssh/sshd_config; then
      sed -i 's/^Port .*/Port 1337/' /etc/ssh/sshd_config
    else
      echo "Port 1337" >> /etc/ssh/sshd_config
    fi
    # Ensure PasswordAuthentication is disabled (Best Practice)
    sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
    # Ensure Root login is disabled (Best Practice)
    sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
    systemctl restart sshd

    # Configure UFW (OS Firewall)
    ufw allow 1337/tcp comment 'Allow SSH on custom port'
    ufw allow 8080/tcp comment 'Allow Jenkins UI'
    # Allow necessary outbound traffic if default policy is deny (default is usually allow outgoing)
    # ufw allow out 53 comment 'Allow DNS outbound'
    # ufw allow out 80 comment 'Allow HTTP outbound'
    # ufw allow out 443 comment 'Allow HTTPS outbound'
    # Enable UFW non-interactively
    ufw --force enable

    # Start and enable Jenkins (restart in case previous start failed due to port binding/firewall)
    systemctl restart jenkins || true # Attempt restart, ignore error if already stopped
    systemctl start jenkins
    systemctl enable jenkins

    echo "Jenkins setup and firewall configuration complete."
  EOF

  tags = {
    Name = "${var.project_name}-jenkins"
  }
}

output "jenkins_instance_public_ip" {
  description = "Public IP address of the Jenkins server"
  value       = aws_instance.jenkins.public_ip
}

output "jenkins_instance_id" {
  description = "ID of the Jenkins EC2 instance"
  value       = aws_instance.jenkins.id
}

# Added output for easily constructing Ansible inventory for Jenkins
output "jenkins_ansible_inventory" {
  description = "Pre-formatted entry for Ansible inventory for Jenkins"
  value = <<-EOT
    [jenkins]
    ${aws_instance.jenkins.public_ip} ansible_host=${aws_instance.jenkins.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/${var.ssh_key_name}.pem ansible_ssh_port=1337
  EOT
  sensitive = false # IP address is public info
}