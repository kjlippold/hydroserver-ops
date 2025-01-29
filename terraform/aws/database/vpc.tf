# ---------------------------------
# Private VPC for RDS
# ---------------------------------

resource "aws_vpc" "rds_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    "${var.label_key}" = local.label_value
  }
}


# ---------------------------------
# Private Subnets for RDS
# ---------------------------------

resource "aws_subnet" "rds_subnet_a" {
  vpc_id                  = aws_vpc.rds_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = false

  tags = {
    "${var.label_key}" = local.label_value
  }
}

resource "aws_subnet" "rds_subnet_b" {
  vpc_id                  = aws_vpc.rds_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.region}b"
  map_public_ip_on_launch = false

  tags = {
    "${var.label_key}" = local.label_value
  }
}


# ---------------------------------
# Security Group for RDS
# ---------------------------------

resource "aws_security_group" "rds_sg" {
  vpc_id = aws_vpc.rds_vpc.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "${var.label_key}" = local.label_value
  }
}


# ---------------------------------
# VPC Endpoint
# ---------------------------------

resource "aws_vpc_endpoint" "rds_endpoint" {
  vpc_id            = aws_vpc.rds_vpc.id
  service_name      = "com.amazonaws.${var.region}.rds"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.rds_subnet_a.id]
  security_group_ids = [aws_security_group.rds_sg.id]

  tags = {
    "${var.label_key}" = local.label_value
  }
}


# ---------------------------------
# App Runner VPC Connector
# ---------------------------------

resource "aws_apprunner_vpc_connector" "app_runner_vpc_connector" {
  vpc_connector_name = "hydroserver-${var.instance}"
  subnets            = [aws_subnet.rds_subnet_a.id, aws_subnet.rds_subnet_b.id]
  security_groups    = [aws_security_group.rds_sg.id]

  tags = {
    "${var.label_key}" = local.label_value
  }
}
