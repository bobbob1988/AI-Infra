resource "aws_vpc" "kubeflow" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "kubeflow-vpc"
  }
}

resource "aws_subnet" "kubeflow" {
  count             = 2
  vpc_id            = aws_vpc.kubeflow.id
  cidr_block        = "10.0.${count.index + 1}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "kubeflow-subnet-${count.index + 1}"
  }
}

resource "aws_internet_gateway" "kubeflow" {
  vpc_id = aws_vpc.kubeflow.id

  tags = {
    Name = "kubeflow-igw"
  }
}

resource "aws_route_table" "kubeflow" {
  vpc_id = aws_vpc.kubeflow.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.kubeflow.id
  }

  tags = {
    Name = "kubeflow-rt"
  }
}

resource "aws_route_table_association" "kubeflow" {
  count          = 2
  subnet_id      = aws_subnet.kubeflow[count.index].id
  route_table_id = aws_route_table.kubeflow.id
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Update the subnet_ids variable
locals {
  subnet_ids = aws_subnet.kubeflow[*].id
} 