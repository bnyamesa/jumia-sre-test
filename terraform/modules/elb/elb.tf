variable "project_name" { type = string }
variable "vpc_id" { type = string }
variable "subnet_ids" { type = list(string) }
variable "security_groups" { type = list(string) }
variable "target_instance_id" { type = string }

resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.security_groups
  subnets            = var.subnet_ids
  enable_deletion_protection = false
  tags = { Name = "${var.project_name}-alb" }
}

resource "aws_lb_target_group" "frontend" {
  name        = "${var.project_name}-tg-frontend"
  port        = 8081
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"
  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
  lifecycle { create_before_destroy = true }
  tags = { Name = "${var.project_name}-tg-frontend" }
}

resource "aws_lb_target_group_attachment" "frontend_attach" {
  target_group_arn = aws_lb_target_group.frontend.arn
  target_id        = var.target_instance_id
  port             = 8081
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

output "alb_dns_name" {
  value = aws_lb.main.dns_name
}
output "alb_zone_id" {
  value = aws_lb.main.zone_id
}
output "target_group_frontend_arn" {
  value = aws_lb_target_group.frontend.arn
}
