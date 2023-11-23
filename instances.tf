resource "aws_instance" "bastion_host_1" {
  ami                    = "ami-0fc5d935ebf8bc3bc"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.subnet_publica_1.id
  vpc_security_group_ids = [aws_security_group.sg_bastion.id]
  key_name               = aws_key_pair.key_pair.key_name


  tags = {
    Name = "Bastion Host 1"
  }
}

resource "aws_instance" "bastion_host_2" {
  ami                    = "ami-0fc5d935ebf8bc3bc"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.subnet_publica_2.id
  vpc_security_group_ids = [aws_security_group.sg_bastion.id]
  key_name               = aws_key_pair.key_pair.key_name

  tags = {
    Name = "Bastion Host 2"
  }
}

resource "aws_instance" "web_server_1" {
  ami                    = "ami-0fc5d935ebf8bc3bc"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.subnet_privada_1.id
  vpc_security_group_ids = [aws_security_group.sg_web.id]
  key_name               = aws_key_pair.key_pair.key_name

  tags = {
    Name = "Web Server 1"
  }
}

resource "aws_instance" "web_server_2" {
  ami                    = "ami-0fc5d935ebf8bc3bc"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.subnet_privada_2.id
  vpc_security_group_ids = [aws_security_group.sg_web.id]
  key_name               = aws_key_pair.key_pair.key_name

  tags = {
    Name = "Web Server 2"
  }
}

resource "aws_key_pair" "key_pair" {
  key_name   = "id_rsa.pub"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCzMeLrNAK40kahNSY5MVQ3dIKeHqWXD/uXrkL6dUmW/R7q4FUfgpUESAfPLQVbw+UVtvJcNjVe6OTZk3U4S7L0J0vRw6U+LClYJmqOV62HePDiD2/Xvs6AAhf4Kh+E3ExjBI8afRQQFnGXjeV25OULeRk4vcc2PBgPMJj3yw88Ld6qWpca2OCQ0bSKFv5tYm4/ZnHC9KcFTPjCpErxDTa2S6TvtZ0jmhthBdw9TEJuTA3YxLOXBTUUPJ9nm9YDXycAMzTnhCtgsTzXLYAN902xmT2aZndGKpKAdduVaxpULOGMGzSuZ930prohrA21lz5fTYrgq4iSHBs1OtS9DYZ4Q1xwo39bHbbeqnscEV0Q8YGOt4S+sH8wUbWR5uHdgzYHqw8uVqtwnzo03jpk7O8AFMuNnL54CQZUEurhpE6il8PbGlvFCF+E9N+uQUlRaBTUCMGccbm9Vid6VizJZNCmQvBPoS4pRlvW6NavA/OHfblBi2BsC7VP6RclwQT7Ikc= srd@obli-srd"
}

resource "aws_lb_target_group" "web-servers" {
  name     = "web-servers"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc-srd.id

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    path                = "/"
    port                = "traffic-port"
  }

  tags = {
    Name = "TG_web-servers"
  }
}

resource "aws_lb" "ALB" {
  name               = "ALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_alb.id]
  subnets            = [aws_subnet.subnet_publica_1.id, aws_subnet.subnet_publica_2.id]

  tags = {
    Name = "ALB"
  }
}
//FALTA CREAR EL LISTENER PARA HTTPS
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.ALB.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web-servers.arn
  }

  tags = {
    Name = "ALB_Listener"
  }
}

resource "aws_lb_target_group_attachment" "Web1" {
  target_group_arn = aws_lb_target_group.web-servers.arn
  target_id        = aws_instance.web_server_1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "Web2" {
  target_group_arn = aws_lb_target_group.web-servers.arn
  target_id        = aws_instance.web_server_2.id
  port             = 80
}