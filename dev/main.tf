# vpc
resource "aws_vpc" "main" {
  cidr_block = "10.1.0.0/16"
}

resource "aws_subnet" "main_public_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.1.0.0/24"
  availability_zone = "ap-northeast-1a"
}
resource "aws_subnet" "main_public_c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.1.1.0/24"
  availability_zone = "ap-northeast-1c"
}
resource "aws_subnet" "main_public_d" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.1.2.0/24"
  availability_zone = "ap-northeast-1d"
}
resource "aws_subnet" "main_private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.1.3.0/24"
  availability_zone = "ap-northeast-1a"
}
resource "aws_subnet" "main_private_c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.1.4.0/24"
  availability_zone = "ap-northeast-1c"
}
resource "aws_subnet" "main_private_d" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.1.5.0/24"
  availability_zone = "ap-northeast-1d"
}

# igw & nat
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}
resource "aws_eip" "main" {
  domain = "vpc"
}
resource "aws_nat_gateway" "main" {
  subnet_id     = aws_subnet.main_public_a.id
  allocation_id = aws_eip.main.id
  depends_on    = [aws_internet_gateway.main]
}

## route table
resource "aws_route_table" "main_public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}
resource "aws_route_table" "main_private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }
}
resource "aws_route_table_association" "main_public_a" {
  subnet_id      = aws_subnet.main_public_a.id
  route_table_id = aws_route_table.main_public.id
}
resource "aws_route_table_association" "main_public_c" {
  subnet_id      = aws_subnet.main_public_c.id
  route_table_id = aws_route_table.main_public.id
}
resource "aws_route_table_association" "main_public_d" {
  subnet_id      = aws_subnet.main_public_d.id
  route_table_id = aws_route_table.main_public.id
}
resource "aws_route_table_association" "main_private_a" {
  subnet_id      = aws_subnet.main_private_a.id
  route_table_id = aws_route_table.main_private.id
}
resource "aws_route_table_association" "main_private_c" {
  subnet_id      = aws_subnet.main_private_c.id
  route_table_id = aws_route_table.main_private.id
}
resource "aws_route_table_association" "main_private_d" {
  subnet_id      = aws_subnet.main_private_d.id
  route_table_id = aws_route_table.main_private.id
}

# cluster
resource "aws_ecs_cluster" "main" {
  name = "devcontainer-terraform-template"
}
resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = ["FARGATE"]
}
