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

resource "aws_vpc" "vpc_0_0" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "0_0_VPC"
  }
}

resource "aws_subnet" "subnet_10_0" {
  vpc_id                  = aws_vpc.vpc_0_0.id
  cidr_block              = "10.10.10.0/24"
  availability_zone       = "eu-north-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Subnet_10_0_24"
  }
}

resource "aws_subnet" "subnet_20_0" {
  vpc_id                  = aws_vpc.vpc_0_0.id
  cidr_block              = "10.10.20.0/24"
  availability_zone       = "eu-north-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "Subnet_20_0_24"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc_0_0.id

  tags = {
    Name = "InternetGateway"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc_0_0.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "PublicRouteTable"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet_10_0.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.subnet_20_0.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_ecs_cluster" "main" {
  name = "conttapp-cluster"
}

# Output variables for debugging
output "aws_account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  value = data.aws_region.current.name
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_ecs_task_definition" "main" {
  family                   = "conttapp-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = file("${path.module}/ecs_task_definition.json")

  execution_role_arn = "arn:aws:iam::637423446150:role/ecsTaskExecutionRole"
  task_role_arn      = "arn:aws:iam::637423446150:role/ecsTaskRole"
}

resource "aws_security_group" "alb" {
  name        = "allow-http"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.vpc_0_0.id

  ingress {
    description = "HTTP from VPC"
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

resource "aws_lb" "main" {
  name               = "conttapp-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.subnet_10_0.id, aws_subnet.subnet_20_0.id]
}

resource "aws_lb_target_group" "main" {
  name        = "conttapp-tg-new"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc_0_0.id
  target_type = "ip"
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

resource "aws_ecs_service" "main" {
  name            = "conttapp-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.subnet_10_0.id, aws_subnet.subnet_20_0.id]
    security_groups = [aws_security_group.alb.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = "conttapp-container"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener.http]
}
