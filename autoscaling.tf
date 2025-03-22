#Creating a Launch Template
resource "aws_launch_template" "my_ecapp_launch_template" {
  name_prefix   = "my-ecapp-template-"
  image_id      = aws_ami_from_instance.ecapp-websv-ami.id
  instance_type = "t2.small"
  key_name      = "ecapp_keypair" 

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.web_sg.id]
    #subnet_id                   = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "ecapp-asg-instance-lt"
    }
  }
}

#Creating an Auto Scaling Group
resource "aws_autoscaling_group" "my_asg" {
  name = "ecapp-asg"
  desired_capacity     = 2
  min_size            = 2
  max_size            = 3
  vpc_zone_identifier = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id] # Use private subnets
  target_group_arns   = [aws_lb_target_group.ecapp_target_group.arn]

  launch_template {
    id      = aws_launch_template.my_ecapp_launch_template.id
    version = "$Latest"
  }
}

#Creating a Target Group
resource "aws_lb_target_group" "ecapp_target_group" {
  name     = "ecapp-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/index.php"
    port                = "80"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 6
  }

   stickiness {
    type = "lb_cookie"
    # cookie_duration = 300
   }

}

#Creating a Load Balancer
resource "aws_lb" "ecapp_alb" {
  name               = "ecapp-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_sg.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]

  enable_deletion_protection = false
}

#Creating a Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.ecapp_alb.arn
  port              = 80 #TODO: Change to 443 for HTTPS
  protocol          = "HTTP"
  #ssl_policy        = "ELBSecurityPolicy-2016-08"
  #certificate_arn   = aws_acm_certificate.my_cert.arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecapp_target_group.arn
  }
}

#Associating the Auto Scaling Group with the Load Balancer
resource "aws_autoscaling_attachment" "alb-asg-associate" {
  autoscaling_group_name = aws_autoscaling_group.my_asg.name
  lb_target_group_arn   = aws_lb_target_group.ecapp_target_group.arn
}


output "alb_dns_name" {
  description = "Application Load Balancer DNS:"
  value       = aws_lb.ecapp_alb.dns_name
}

output "ecapp_web_url" {
  description = "ECommerce Group 10 - Webapp URL:"
  value       = "http://${aws_lb.ecapp_alb.dns_name}"
}



#Creating an Auto Scaling Policy for CPU Utilization (Target Tracking)
resource "aws_autoscaling_policy" "cpu_target_tracking" {
  name                   = "cpu-scaling-policy"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.my_asg.name
  
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50.0  # Scaling in/out when CPU utilization reaches 50%
  }
}

#TODO: Create an auto-scaling policy (alarm and scale-in/out policy) based on ALB Request Count
