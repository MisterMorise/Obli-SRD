provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "vpc-srd" {
  cidr_block = "192.168.0.0/16"

    tags = {
    Name = "VPC-SRD"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc-srd.id

    tags = {
        Name = "IGW-SRD"
    }
}

resource "aws_subnet" "subnet_publica_1" {
  vpc_id                  = aws_vpc.vpc-srd.id
  cidr_block              = "192.168.1.0/24"
  map_public_ip_on_launch = true

    tags = {
        Name = "Subnet-Publica-1"
    }
}

resource "aws_subnet" "subnet_publica_2" {
  vpc_id                  = aws_vpc.vpc-srd.id
  cidr_block              = "192.168.2.0/24"
  map_public_ip_on_launch = true

    tags = {
        Name = "Subnet-Publica-2"
    }
}

resource "aws_subnet" "subnet_privada_1" {
  vpc_id     = aws_vpc.vpc-srd.id
  cidr_block = "192.168.3.0/24"

    tags = {
        Name = "Subnet-Privada-1"
    }
}

resource "aws_subnet" "subnet_privada_2" {
  vpc_id     = aws_vpc.vpc-srd.id
  cidr_block = "192.168.4.0/24"

    tags = {
        Name = "Subnet-Privada-2"
    }
}

resource "aws_eip" "eip_nat_gw_1" {
  vpc = true

    tags = {
        Name = "EIP-NAT-GW-1"
    }
}

resource "aws_nat_gateway" "nat_gw_1" {
  subnet_id     = aws_subnet.subnet_publica_1.id
  allocation_id = aws_eip.eip_nat_gw_1.id

    tags = {
        Name = "NAT-GW-1"
    }
}

resource "aws_eip" "eip_nat_gw_2" {
  vpc = true

    tags = {
        Name = "EIP-NAT-GW-2"
    }
}

resource "aws_nat_gateway" "nat_gw_2" {
  subnet_id     = aws_subnet.subnet_publica_2.id
  allocation_id = aws_eip.eip_nat_gw_2.id
    
        tags = {
            Name = "NAT-GW-2"
        }
}

resource "aws_route_table" "publica" {
  vpc_id = aws_vpc.vpc-srd.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

#   route {
#     cidr_block = "192.168.0.0/16"
#     gateway_id = aws_internet_gateway.igw.id
#   }

    tags = {
        Name = "Tabla-de-rutas-Publica"
    }
}

resource "aws_route_table_association" "publica_1" {
  subnet_id      = aws_subnet.subnet_publica_1.id
  route_table_id = aws_route_table.publica.id
}

resource "aws_route_table_association" "publica_2" {
  subnet_id      = aws_subnet.subnet_publica_2.id
  route_table_id = aws_route_table.publica.id
}

resource "aws_route_table" "privada_1" {
  vpc_id = aws_vpc.vpc-srd.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw_1.id
  }

#   route {
#     cidr_block = "192.168.0.0/16"
#     gateway_id = aws_internet_gateway.igw.id
#   }
    
        tags = {
            Name = "Tabla-de-rutas-Privada-1"
        }
}

resource "aws_route_table_association" "as_privada_1" {
  subnet_id      = aws_subnet.subnet_privada_1.id
  route_table_id = aws_route_table.privada_1.id
}

resource "aws_route_table" "privada_2" {
  vpc_id = aws_vpc.vpc-srd.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw_2.id
  }

#   route {
#     cidr_block = "192.168.0.0/16"
#     gateway_id = aws_internet_gateway.igw.id
#   }
        
            tags = {
                Name = "Tabla-de-rutas-Privada-2"
            }
}

resource "aws_route_table_association" "as_privada_2" {
  subnet_id      = aws_subnet.subnet_privada_2.id
  route_table_id = aws_route_table.privada_2.id
}
