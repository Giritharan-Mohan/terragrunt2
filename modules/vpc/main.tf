
# Create VPC
resource "aws_vpc" "vpc" {
  cidr_block             = var.vpc_cidr_block
  enable_dns_support     = var.enable_dns_support
  enable_dns_hostnames   = var.enable_dns_hostnames

  tags = {
    Name = var.vpcname
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = var.igwname
  }
}

# # Fetch available availability zones for the specified region
data "aws_availability_zones" "available" {

}



# Create Public Subnets
resource "aws_subnet" "public" {

  count             = length(var.public_subnet_cidr_blocks)
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.public_subnet_cidr_blocks[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "Infra-public${count.index + 1}"
  }
}

# Create Private Subnets
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidr_blocks)
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.private_subnet_cidr_blocks[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "Infra-private${count.index + 1}"
  }
}

# Create Route Table for public IP
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = var.rtname
  }
}

# Associate Public Subnets with Route Table
resource "aws_route_table_association" "subnet_association" {
  count           = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

# Create Default Route Table for private IP
resource "aws_default_route_table" "default" {
  default_route_table_id = aws_vpc.vpc.default_route_table_id

  tags = {
    Name = "default"
  }
}

# Associate Private Subnets with Default Route Table
resource "aws_route_table_association" "private_subnet_association" {
  count           = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_default_route_table.default.id
}

# Create Network ACL
resource "aws_network_acl" "nacl" {
  vpc_id = aws_vpc.vpc.id

  egress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = aws_vpc.vpc.cidr_block
    from_port  = 443
    to_port    = 443
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = aws_vpc.vpc.cidr_block
    from_port  = 80
    to_port    = 80
  }

  tags = {
    Name = var.naclname
  }
}

resource "aws_network_acl_association" "naclass" {
  
  count          = length(aws_subnet.public)
  network_acl_id = aws_network_acl.nacl.id
  subnet_id      = aws_subnet.public[count.index].id 
}

resource "aws_default_network_acl" "default" {
  default_network_acl_id = aws_vpc.vpc.default_network_acl_id

  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
 tags = {
    Name = "default-${var.naclname}"
}
}

resource "aws_network_acl_association" "default" {
  
  count          = length(aws_subnet.private)
  network_acl_id = aws_default_network_acl.default.id
  subnet_id      = aws_subnet.private[count.index].id 
}
