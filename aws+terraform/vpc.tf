# Create primary vpc in Sydney region
resource "aws_vpc" "primary_vpc" {
  cidr_block       = local.main_vpc_cidr
  instance_tenancy = "default"

  # enable_dns_support   = true
  # enable_dns_hostnames = true

  tags = {
    Name = "primary vpc"
  }
}

# Create 1 public Subnet
# Create 1 Private Subnet with NAT
# Create 1 Private Subnet without NAT
resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.primary_vpc.id
  cidr_block        = local.public_subnet_cidr
  availability_zone = "ap-southeast-2a"

  tags = {
    Name = "Public Subnet"
  }
}

resource "aws_subnet" "private_subnet_A" {
  vpc_id            = aws_vpc.primary_vpc.id
  cidr_block        = local.private_subnet_withNAT_cidr
  availability_zone = "ap-southeast-2a"

  tags = {
    Name = "Private Subnet A"
  }
}

resource "aws_subnet" "private_subnet_B" {
  vpc_id            = aws_vpc.primary_vpc.id
  cidr_block        = local.private_subnet_noNAT_cidr
  availability_zone = "ap-southeast-2b"

  tags = {
    Name = "Private Subnet B"
  }
}

# Create IGW, RT
resource "aws_internet_gateway" "primary_igw" {
  vpc_id = aws_vpc.primary_vpc.id

  tags = {
    Name = "primary_igw"
  }
}

# create Public route table - add rule, subnet assocoation - public subnet
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.primary_vpc.id

  tags = {
    Name = "Public RT"
  }
}

resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.primary_igw.id
}

resource "aws_route_table_association" "public_route_table_assocoation" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

# create Private route table - subnet association - private subnet, private subnet secondary
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.primary_vpc.id

  tags = {
    Name = "Private RT"
  }
}

resource "aws_route_table_association" "private_RT_asso_A" {
  subnet_id      = aws_subnet.private_subnet_A.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_RT_asso_B" {
  subnet_id      = aws_subnet.private_subnet_B.id
  route_table_id = aws_route_table.private_route_table.id
}
