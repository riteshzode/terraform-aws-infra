# create a vpc
resource "aws_vpc" "my_vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.tag.Name}"
  }
}

# create public subnets
resource "aws_subnet" "public_subnet" {
  count = length(var.availability_zones)
  vpc_id = aws_vpc.my_vpc.id
  cidr_block = var.public_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-${count.index}"
  }
}

# create private subnets
resource "aws_subnet" "private_subnet" {
  count = length(var.availability_zones)
  vpc_id = aws_vpc.my_vpc.id
  cidr_block = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name = "private-subnet-${count.index}"
  }
}

# create internet gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "${var.tag.Name}-igw"
  }
}

# Create Elastic IP for NAT Gateway
resource "aws_eip" "nat_ip" {
  tags = {
    Name = "${var.tag.Name}-nat-ip"
  }
}


# create a single NAT Gateway in the first public subnet
resource "aws_nat_gateway" "my_nat_gateway" {
  allocation_id = aws_eip.nat_ip.id
  subnet_id = aws_subnet.public_subnet[0].id
  tags = {
    Name = "${var.tag.Name}-nat-gateway"
  }
}


# create route table for public subnets
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "${var.tag.Name}-public-route-table"
  }
}

# create route for public route table
resource "aws_route" "public_route" {
  route_table_id = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.my_igw.id
}

# associate public route table with public subnets
resource "aws_route_table_association" "public_route_table_association" {
  count = length(var.availability_zones)
  subnet_id = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

# create route table for private subnets
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "${var.tag.Name}-private-route-table"
  }
}

# create route for private route table to NAT Gateway
resource "aws_route" "private_route" {
  route_table_id = aws_route_table.private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.my_nat_gateway.id
}

# associate private route table with private subnets
resource "aws_route_table_association" "private_route_table_association" {
  count = length(var.availability_zones)
  subnet_id = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_route_table.id
}

# create security group for all traffic allowed
resource "aws_security_group" "my_sg" {
  vpc_id = aws_vpc.my_vpc.id
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.tag.Name}"
  }
}

# add endpoint for S3 take region form provider
resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id = aws_vpc.my_vpc.id
  service_name = "com.amazonaws.${var.aws_region}.s3"
  route_table_ids = [aws_route_table.private_route_table.id]
}

// connect endpoint with public subnet route table
resource "aws_route_table_association" "s3_endpoint_association" {
  subnet_id = aws_subnet.public_subnet[0].id
  route_table_id = aws_route_table.public_route_table.id
}

