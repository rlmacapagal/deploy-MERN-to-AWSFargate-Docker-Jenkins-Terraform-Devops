
# resource "aws_security_group" "lb" {
#   name        = "mern-stack-load-balancer-security-group"
#   description = "controls access to the ALB"
#   vpc_id      = aws_vpc.main.id

#   ingress {
#     protocol    = "tcp"
#     from_port   = var.app_port
#     to_port     = var.app_port
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     protocol    = "-1"
#     from_port   = 0
#     to_port     = 0
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# resource "aws_security_group" "ecs_tasks" {
#   name          = "mern-stack-task-security-group"
#   description   = "allow inbund acces from the alb "
#   vpc_id        = aws_vpc.main.id

#   ingress {
#     protocol     = "tcp"
#     from_port    = var.app_port
#     to_port      = var.app_port
#     security_groups = [aws_security_group.lb.id]

#   }

#   egress { 
#     protocol     = "-1"
#     from_port    = 0
#     to_port      = 0 
#     cidr_blocks  = ["0.0.0.0/0"]
#   }
# }



# security.tf

# ALB Security Group: Edit to restrict access to the application
resource "aws_security_group" "lb" {
  name        = "myapp-load-balancer-security-group"
  description = "controls access to the ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    protocol    = "tcp"
    from_port   = var.app_port
    to_port     = var.app_port
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Traffic to the ECS cluster should only come from the ALB
resource "aws_security_group" "ecs_tasks" {
  name        = "myapp-ecs-tasks-security-group"
  description = "allow inbound access from the ALB only"
  vpc_id      = aws_vpc.main.id

  ingress {
    protocol        = "tcp"
    from_port       = var.app_port
    to_port         = var.app_port
    security_groups = [aws_security_group.lb.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# resource "aws_security_group" "mongodb_sg" {
#   name        = "mongodb-sg"
#   description = "Security group for MongoDB"
#   vpc_id = aws_vpc.main.id 

#   ingress {
#     from_port   = 27017
#     to_port     = 27017
#     protocol    = "tcp"
#     security_groups = [aws_security_group.ecs_tasks.id]  # Dikkatli olun, güvenlik nedeniyle daha kısıtlı IP aralıklarını tercih edebilirsiniz.
#   }
  
#   # ...
# }