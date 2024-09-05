# Provider configuration
provider "aws" {
  region = var.aws_region
}

# VPC and networking
resource "aws_vpc" "medusa_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "medusa-vpc"
  }
}

resource "aws_subnet" "medusa_subnet_1" {
  vpc_id            = aws_vpc.medusa_vpc.id
  cidr_block        = var.subnet_1_cidr
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "medusa-subnet-1"
  }
}

resource "aws_subnet" "medusa_subnet_2" {
  vpc_id            = aws_vpc.medusa_vpc.id
  cidr_block        = var.subnet_2_cidr
  availability_zone = "${var.aws_region}b"

  tags = {
    Name = "medusa-subnet-2"
  }
}

# Security group
resource "aws_security_group" "medusa_sg" {
  name        = "medusa-sg"
  description = "Security group for Medusa ECS tasks"
  vpc_id      = aws_vpc.medusa_vpc.id

  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ECS cluster
resource "aws_ecs_cluster" "medusa_cluster" {
  name = "medusa-cluster"
}

# ECS task definition
resource "aws_ecs_task_definition" "medusa_task" {
  family                   = "medusa-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([
    {
      name  = "medusa-container"
      image = "${aws_ecr_repository.medusa_repo.repository_url}:latest"
      portMappings = [
        {
          containerPort = 9000
          hostPort      = 9000
        }
      ]
      environment = [
        {
          name  = "DATABASE_TYPE"
          value = "postgres"
        },
        {
          name  = "DATABASE_URL"
          value = var.database_url
        },
        {
          name  = "REDIS_URL"
          value = var.redis_url
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.medusa_logs.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "medusa"
        }
      }
    }
  ])
}

# ECS service
resource "aws_ecs_service" "medusa_service" {
  name            = "medusa-service"
  cluster         = aws_ecs_cluster.medusa_cluster.id
  task_definition = aws_ecs_task_definition.medusa_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = [aws_subnet.medusa_subnet_1.id, aws_subnet.medusa_subnet_2.id]
    security_groups  = [aws_security_group.medusa_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.medusa_tg.arn
    container_name   = "medusa-container"
    container_port   = 9000
  }

  depends_on = [aws_lb_listener.medusa_listener]
}

# Application Load Balancer
resource "aws_lb" "medusa_alb" {
  name               = "medusa-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.medusa_sg.id]
  subnets            = [aws_subnet.medusa_subnet_1.id, aws_subnet.medusa_subnet_2.id]
}

resource "aws_lb_target_group" "medusa_tg" {
  name        = "medusa-tg"
  port        = 9000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.medusa_vpc.id
  target_type = "ip"

  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 60
    interval            = 300
    matcher             = "200"
  }
}

resource "aws_lb_listener" "medusa_listener" {
  load_balancer_arn = aws_lb.medusa_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.medusa_tg.arn
  }
}

# ECR repository
resource "aws_ecr_repository" "medusa_repo" {
  name = "medusa-repo"
}

# IAM role for ECS task execution
resource "aws_iam_role" "ecs_execution_role" {
  name = "medusa-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# CloudWatch log group
resource "aws_cloudwatch_log_group" "medusa_logs" {
  name              = "/ecs/medusa"
  retention_in_days = 30
}

# Output the ALB DNS name
output "alb_dns_name" {
  value       = aws_lb.medusa_alb.dns_name
  description = "The DNS name of the Application Load Balancer"
}