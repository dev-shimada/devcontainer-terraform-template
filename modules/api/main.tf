# execution role
resource "aws_iam_role" "main_execution_role" {
  name = "ApiEcsTaskExecutionRole"
  assume_role_policy = jsonencode({
    "Version" : "2008-10-17",
    "Statement" : [
      {
        "Sid" : "",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ecs-tasks.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}
data "aws_iam_policy" "main_amazon_ecs_task_execution_role_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
resource "aws_iam_role_policy_attachment" "main_amazon_ecs_task_execution_role_policy" {
  role       = aws_iam_role.main_execution_role.name
  policy_arn = data.aws_iam_policy.main_amazon_ecs_task_execution_role_policy.arn
}

# task role
data "aws_caller_identity" "main" {}
resource "aws_iam_role" "main_task_role" {
  name = "ApiEcsTaskRole"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : [
            "ecs-tasks.amazonaws.com"
          ]
        },
        "Action" : "sts:AssumeRole",
        "Condition" : {
          "ArnLike" : {
            "aws:SourceArn" : "arn:aws:ecs:ap-northeast-1:${data.aws_caller_identity.main.account_id}:*"
          },
          "StringEquals" : {
            "aws:SourceAccount" : "${data.aws_caller_identity.main.account_id}"
          }
        }
      }
    ]
  })
}
resource "aws_iam_policy" "main_task_role" {
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:DescribeLogGroups"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogStream",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents"
        ],
        "Resource" : "${aws_cloudwatch_log_group.main.arn}:*"
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "main_task_role" {
  role       = aws_iam_role.main_task_role.name
  policy_arn = aws_iam_policy.main_task_role.arn
}

# log group
resource "aws_cloudwatch_log_group" "main" {
  name              = "api"
  retention_in_days = 180
}

# task definition
resource "aws_ecs_task_definition" "main" {
  family = "api"
  container_definitions = jsonencode([
    {
      name      = "api"
      image     = "${var.image_url}:${var.image_tag}"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
      linuxParameters = {
        "initProcessEnabled" = true
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-region        = "ap-northeast-1"
          awslogs-stream-prefix = "api"
          awslogs-group         = aws_cloudwatch_log_group.main.name
        }
      }
      environment = var.environment
      secrets     = var.secrets
    }
  ])
  execution_role_arn       = aws_iam_role.main_execution_role.arn
  task_role_arn            = aws_iam_role.main_task_role.arn
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  tags                     = {}
  skip_destroy             = true
  track_latest             = true
}

# sg
## lb
resource "aws_security_group" "main_lb" {
  name   = "api-lb"
  vpc_id = var.vpc_id

  egress = [
    {
      description      = "all"
      from_port        = 0
      to_port          = 0
      protocol         = "all"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]
}

data "aws_vpc" "main_vpc" {
  id = var.vpc_id
}

## ecs
resource "aws_security_group" "main_ecs" {
  name   = "api-ecs"
  vpc_id = var.vpc_id

  ingress = [
    {
      description      = "api-lb"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = []
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = [aws_security_group.main_lb.id]
      self             = false
    }
  ]
  egress = [
    {
      description      = "all"
      from_port        = 0
      to_port          = 0
      protocol         = "all"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]
}

# LB
## target group
resource "aws_lb_target_group" "main" {
  name        = "api-target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
  health_check {
    path                = "/"
    interval            = 60
    unhealthy_threshold = 5
  }
}
## listener
resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}
## lb
resource "aws_lb" "main" {
  name               = "api-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.main_lb.id]
  subnets            = var.lb_subnet_ids

  enable_deletion_protection = true
}

# ECS service
data "aws_ecs_task_definition" "main" {
  task_definition = aws_ecs_task_definition.main.family
}
resource "aws_ecs_service" "main" {
  name                   = "api-service"
  launch_type            = "FARGATE"
  cluster                = var.cluster_arn
  task_definition        = data.aws_ecs_task_definition.main.arn
  desired_count          = var.desired_count
  enable_execute_command = true
  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.main_ecs.id]
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = "api"
    container_port   = "80"
  }
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
  deployment_maximum_percent         = var.maximum_percent
  deployment_minimum_healthy_percent = var.minimum_healthy_percent

  propagate_tags = "SERVICE"
}
