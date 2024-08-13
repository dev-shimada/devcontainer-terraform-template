module "api" {
  source = "../modules/api"

  vpc_id      = aws_vpc.main.id
  cluster_arn = aws_ecs_cluster.main.arn
  image_url   = "nginx"
  image_tag   = "latest"
  private_subnet_ids = [
    aws_subnet.main_private_a.id,
    aws_subnet.main_private_c.id,
    aws_subnet.main_private_d.id
  ]
  lb_subnet_ids = [
    aws_subnet.main_public_a.id,
    aws_subnet.main_public_c.id,
    aws_subnet.main_public_d.id
  ]
  desired_count           = 1
  maximum_percent         = 200
  minimum_healthy_percent = 100
}

data "http" "main" {
  url = "https://checkip.amazonaws.com/"
}
resource "aws_security_group_rule" "api_my_ip" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["${chomp(data.http.main.response_body)}/32"]
  security_group_id = module.api.lb_sg.id
}
