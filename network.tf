provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "vpc_srd" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "vpc-srd"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc_srd.id

  tags = {
    Name = "igw"
  }
}

resource "aws_subnet" "subnet_publica" {
  vpc_id                  = aws_vpc.vpc_srd.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "subnet-publica"
  }
}

resource "aws_subnet" "subnet_privada" {
  vpc_id            = aws_vpc.vpc_srd.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "subnet-privada"
  }
}

resource "aws_eip" "nat" {
  vpc = true

  tags = {
    Name = "NAT Privado"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.subnet_publica.id

  tags = {
    Name = "NAT Privado"
  }
}

resource "aws_route_table" "tabla_ruta_publica" {
  vpc_id = aws_vpc.vpc_srd.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "tabla_ruta_publica"
  }
}

resource "aws_route_table_association" "as_tabla_ruta_publica" {
  subnet_id      = aws_subnet.subnet_publica.id
  route_table_id = aws_route_table.tabla_ruta_publica.id
}

resource "aws_route_table" "tabla_ruta_privada" {
  vpc_id = aws_vpc.vpc_srd.id

  tags = {
    Name = "tabla_ruta_privada"
  }
}

resource "aws_route" "nat_gateway_privado" {
  route_table_id         = aws_route_table.tabla_ruta_privada.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "as_tabla_ruta_privada" {
  subnet_id      = aws_subnet.subnet_privada.id
  route_table_id = aws_route_table.tabla_ruta_privada.id
}


resource "aws_security_group" "sg_bastion" {
  name        = "sg_bastion"
  description = "Security group Bastion"
  vpc_id      = aws_vpc.vpc_srd.id

  ingress {
    from_port   = 2939 # SSH hardening
    to_port     = 2939
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg_bastion"
  }

}
resource "aws_security_group" "sg_web" {
  name        = "sg_web"
  description = "Security group WebServer"
  vpc_id      = aws_vpc.vpc_srd.id

  ingress {
    from_port       = 2939 # SSH hardening
    to_port         = 2939
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_bastion.id]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg_web"
  }
}

resource "aws_security_group" "sg_mysql" {
  name        = "mysql"
  description = "Security group MySQL"
  vpc_id      = aws_vpc.vpc_srd.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_web.id]
  }

  ingress {
    from_port       = 2939 # SSH hardening
    to_port         = 2939
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_bastion.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}
