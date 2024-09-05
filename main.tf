provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "medusa_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "medusa_subnet" {
  vpc_id     = aws_vpc.medusa_vpc.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_internet_gateway" "medusa_gw" {
  vpc_id = aws_vpc.medusa_vpc.id
}

resource "aws_route_table" "medusa_route_table" {
  vpc_id = aws_vpc.medusa_vpc.id
}

resource "aws_route" "medusa_route" {
  route_table_id         = aws_route_table.medusa_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.medusa_gw.id
}