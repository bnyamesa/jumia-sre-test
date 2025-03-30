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
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.ssh_key_name
  subnet_id              = element(var.subnet_ids, 0)  // Use the first public subnet for proper public IP assignment
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    # Update package list and install OpenJDK and wget
    apt-get update -y
    apt-get install -y openjdk-11-jdk wget

    # Add Jenkins repository and install Jenkins
    wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | apt-key add -
    echo "deb https://pkg.jenkins.io/debian-stable binary/" > /etc/apt/sources.list.d/jenkins.list
    apt-get update -y
    apt-get install -y jenkins

    # Reconfigure SSH to listen on port 1337
    sed -i 's/#Port 22/Port 1337/' /etc/ssh/sshd_config
    sed -i 's/Port 22/Port 1337/' /etc/ssh/sshd_config
    systemctl restart sshd

    # Start and enable Jenkins
    systemctl start jenkins
    systemctl enable jenkins
  EOF

  tags = {
    Name = "${var.project_name}-jenkins"
  }
}

output "jenkins_instance_public_ip" {
  description = "Public IP address of the Jenkins server"
  value       = aws_instance.jenkins.public_ip
}
