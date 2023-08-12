# # ecs.tf

resource "aws_ecs_cluster" "main" {
  name = "myapp-cluster"
}

data "template_file" "myapp" {
  template = file("./templates/ecs/myapp.json.tpl")

  vars = {
    app_image      = var.app_image
    app_port       = var.app_port
    fargate_cpu    = var.fargate_cpu
    fargate_memory = var.fargate_memory
    aws_region     = var.aws_region
  }
}



resource "aws_ecs_task_definition" "app" {
  family                   = "myapp-task"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory
  container_definitions    = data.template_file.myapp.rendered
}



resource "aws_ecs_service" "main" {
  name            = "myapp-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.app_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = aws_subnet.private.*.id
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.app.id
    container_name   = "myapp"
    container_port   = var.app_port
  }

  depends_on = [aws_alb_listener.front_end, aws_iam_role_policy_attachment.ecs_task_execution_role  ]
}



// IAM rolü ve diğer yapılandırmaları ekleyebilirsiniz

// Uygulama yapılandırmasını güncelleyin
// Bağlantı dizisi ve diğer uygulama ayarlarını kontrol edin

// Güvenlik grupları ve ağ izinleri için gereken yapılandırmaları ekleyin



# resource "aws_security_group" "mongodb_sg" {
#   name_prefix = "mongodb-sg-"

#   // Gerekli güvenlik grubu ayarlarını burada tanımlayın
#   vpc_id = aws_vpc.main.id  // Bu, güvenlik grubunun hangi VPC'ye ait olduğunu belirtir

#   // MongoDB'ye dışarıdan erişimi kısıtlamak için gerekli kaynakların IP adreslerini veya aralıklarını belirtin
#   // Örnek: Allow trafik from the same security group (ECS görevleri arasında)
#   ingress {
#     from_port   = 27017
#     to_port     = 27017
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"] 
#   }
  
#   // Diğer gerektiğinde ingress (giriş) ve egress (çıkış) kurallarını ekleyebilirsiniz
# }



# resource "aws_ecs_task_definition" "mongodb" {
#   family                   = "mongodb-task"
#   execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
#   network_mode             = "awsvpc"
#   requires_compatibilities = ["FARGATE"]
#   cpu                      = "256"  # Örnek olarak
#   memory                   = "512"  # Örnek olarak

#   container_definitions = jsonencode([
#     {
#       name  = "my-mongodb",  # MongoDB konteynerının adını burada belirtin
#       image = "mongo",  # MongoDB Docker imajı
#       portMappings = [
#         {
#           containerPort = 27017,  # MongoDB standart portu
#         },
#       ],
#     },
#   ])
# }

# resource "aws_ecs_task_definition" "mongo_task" {
#   family                   = "mongo-task"
#   execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
#   network_mode             = "awsvpc"
#   requires_compatibilities = ["FARGATE"]
#   memory                   = "512"
#   cpu                      = "256"



#   container_definitions = jsonencode([{
#     name  = "mongo-container"
#     image = "mongo:latest"  # Kullanacağınız MongoDB görüntüsünü buraya ekleyin
#     portMappings = [{
#       containerPort = 27017
#     }]
#   }])
# }


# resource "aws_ecs_service" "mongo_service" {
#   name            = "mongo-service"
#   cluster         = aws_ecs_cluster.main.id
#   task_definition = aws_ecs_task_definition.mongo_task.arn
#   launch_type     = "FARGATE"
  

#   network_configuration {
#     security_groups  = [aws_security_group.mongodb_sg.id]
#     subnets          = aws_subnet.private.*.id
#     assign_public_ip = true
#   }
#   depends_on = [aws_iam_role_policy_attachment.ecs_task_execution_role, aws_ecs_task_definition.mongo_task]

# }
# resource "aws_security_group" "mongo_sg" {
#   name_prefix = "mongo-sg-"
  
#   // MongoDB'ye gelen trafiği izin vermek için gerekli kuralları ekleyin
#   ingress {
#     from_port   = 27017
#     to_port     = 27017
#     protocol    = "tcp"
#     cidr_blocks = ["10.0.0.0/16"]  # VPC CIDR aralığını güncelleyin
#   }
# }