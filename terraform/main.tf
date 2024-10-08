terraform {
  backend "s3" {
    bucket         = "constantine-z"
    region         = "eu-north-1"
    encrypt        = true
    key            = "tfcontt.tfstate"
  }
}

provider "aws" {
  region = "eu-north-1"
}


resource "aws_vpc" "simple_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "simple_vpc"
    ENV="Test"
  }
}


resource "aws_subnet" "simple_subnet" {
  vpc_id                  = aws_vpc.simple_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-north-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "simple_subnet"
    ENV="Test"
  }
}


resource "aws_internet_gateway" "simple_igw" {
  vpc_id = aws_vpc.simple_vpc.id

  tags = {
    Name = "simple_igw"
    ENV="Test"
  }
}


resource "aws_route_table" "simple_rt" {
  vpc_id = aws_vpc.simple_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.simple_igw.id
  }

  tags = {
    Name = "simple_rt"
  }
}


resource "aws_route_table_association" "simple_rta" {
  subnet_id      = aws_subnet.simple_subnet.id
  route_table_id = aws_route_table.simple_rt.id
}


resource "aws_security_group" "simple_sg" {
  vpc_id      = aws_vpc.simple_vpc.id
  name        = "simple_sg"
  description = "Allow HTTP traffic"

  ingress {
    from_port   = 80
    to_port     = 80
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


resource "aws_iam_role" "ecsTaskExecutionRole" {
  name = "ecsTaskExecutionRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"  # root console access
  ]
}


resource "aws_iam_role" "ecsTaskRole" {
  name = "ecsTaskRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  inline_policy {
    name   = "ecsTaskPolicy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [ #log+root console access
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            "ssmmessages:CreateControlChannel",
            "ssmmessages:CreateDataChannel",
            "ssmmessages:OpenControlChannel",
            "ssmmessages:OpenDataChannel"
          ]
          Resource = "*"
        }
      ]
    })
  }
}

#loging
resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name = "/ecs/simple-container"
  retention_in_days = 7
}


resource "aws_ecs_cluster" "simple_cluster" {
  name = "simple-cluster"
}


resource "aws_ecs_task_definition" "simple_task" {
  family                   = "simple-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([
    {
      name      = "simple-container"
      image     = "637423446150.dkr.ecr.eu-north-1.amazonaws.com/conttapp:latest"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
      logConfiguration = { #loging
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_log_group.name
          "awslogs-region"        = "eu-north-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
      memory = 512
      cpu    = 256
    }
  ])

  execution_role_arn = aws_iam_role.ecsTaskExecutionRole.arn
  task_role_arn      = aws_iam_role.ecsTaskRole.arn
}


resource "aws_ecs_service" "simple_service" {
  name                    = "simple-service"
  cluster                 = aws_ecs_cluster.simple_cluster.id
  task_definition         = aws_ecs_task_definition.simple_task.arn
  desired_count           = 1
  launch_type             = "FARGATE"
  enable_execute_command  = true #root console access
 #aws ecs update-service --cluster simple-cluster --service simple-service --enable-execute-command --force-new-deployment


  network_configuration {
    subnets         = [aws_subnet.simple_subnet.id]
    security_groups = [aws_security_group.simple_sg.id]
    assign_public_ip = true
  }
}
