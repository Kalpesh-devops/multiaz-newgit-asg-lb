resource "aws_subnet" "public-subnets" {
  vpc_id            = aws_vpc.main.id
  count             = length(var.az-subnets)
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + 10)
  availability_zone = element(var.az-subnets, count.index)
  tags = {
    Name = "public-subnets-${count.index + 1}"
  }
}

resource "aws_subnet" "private-subnets" {
  vpc_id            = aws_vpc.main.id
  count             = length(var.az-subnets)
  availability_zone = element(var.az-subnets, count.index)
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + 13)
  tags = {
    Name = "private-subnets-${count.index + 1}"
  }

}

resource "aws_internet_gateway" "igw-multiaz" {
  vpc_id = aws_vpc.main.id
  tags = {
    name = "igw-multiaz"

  }

}

resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw-multiaz.id
  }
  tags = {

    Name = " public-route-table"
  }
}

resource "aws_route_table_association" "public-association" {
  route_table_id = aws_route_table.public-route-table.id
  count          = length(var.az-subnets)
  subnet_id      = element(aws_subnet.public-subnets[*].id, count.index)

}
resource "aws_eip" "eip" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.igw-multiaz]

}

resource "aws_nat_gateway" "nate-gate-multiaz" {
  allocation_id = aws_eip.eip.id
  subnet_id     = element(aws_subnet.public-subnets[*].id, 0)
  tags = {
    name = "nate-gate-multiaz"
  }

}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nate-gate-multiaz.id

  }
  depends_on = [aws_nat_gateway.nate-gate-multiaz]
  tags = {
    name = "private_route_table"
  }
}

resource "aws_route_table_association" "private_table_association" {
  route_table_id = aws_route_table.private_route_table.id
  count          = length(var.az-subnets)
  subnet_id      = element(aws_subnet.private-subnets[*].id, count.index)



}

