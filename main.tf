provider "aws" {
  region = var.region
}

# --- REDES ---
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name   = "minecraft_vpc"
  cidr   = "10.0.0.0/16"
  azs    = ["${var.region}a", "${var.region}b", "${var.region}c"]
  public_subnets = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  
  enable_nat_gateway = false
  enable_vpn_gateway = false
}

# --- ALMACENAMIENTO (EFS) ---
resource "aws_efs_file_system" "minecraft_data" {
  creation_token = "minecraft-data"
  encrypted      = true
  tags           = { Name = "MinecraftData" }
}

resource "aws_efs_mount_target" "minecraft_mount" {
  count           = 3
  file_system_id  = aws_efs_file_system.minecraft_data.id
  subnet_id       = module.vpc.public_subnets[count.index]
  security_groups = [aws_security_group.minecraft_server.id]
}

# --- SEGURIDAD ---
resource "aws_security_group" "minecraft_server" {
  name   = "minecraft_sg"
  vpc_id = module.vpc.vpc_id
 
  ingress {
    from_port   = 25565
    to_port     = 25565
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 2049
    to_port   = 2049
    protocol  = "tcp"
    self      = true
  }
 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- COMPUTO (ECS) ---
resource "aws_ecs_cluster" "minecraft_server" {
  name = "minecraft_cluster"
}

resource "aws_ecs_task_definition" "minecraft_server" {
  family                   = "minecraft-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.ecs_tasks_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_tasks_execution_role.arn

  container_definitions = jsonencode([{
    name  = "minecraft-server"
    image = "itzg/minecraft-server"
    portMappings = [{ containerPort = 25565, hostPort = 25565, protocol = "tcp" }]
    environment = [
      { name = "EULA", value = "TRUE" },
      { name = "VERSION", value = var.minecraft_version },
      { name = "TYPE", value = "PAPER" }
    ]
    mountPoints = [{ containerPath = "/data", sourceVolume = "minecraft-data" }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.minecraft_log_group.name
        awslogs-region        = var.region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])

  volume {
    name = "minecraft-data"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.minecraft_data.id
      root_directory = "/"
    }
  }
}

resource "aws_ecs_service" "minecraft_server" {
  name            = "minecraft_service"
  cluster         = aws_ecs_cluster.minecraft_server.id
  task_definition = aws_ecs_task_definition.minecraft_server.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = module.vpc.public_subnets
    security_groups  = [aws_security_group.minecraft_server.id]
    assign_public_ip = true
  }
  depends_on = [aws_efs_mount_target.minecraft_mount]
}

# --- LOGS Y ROLES ---
resource "aws_cloudwatch_log_group" "minecraft_log_group" {
  name              = "/ecs/minecraft-server"
  retention_in_days = 7
}

resource "aws_iam_role" "ecs_tasks_execution_role" {
  name               = "minecraft_ecs_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_tasks_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_logs" {
  role       = aws_iam_role.ecs_tasks_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}