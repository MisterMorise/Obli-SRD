resource "aws_instance" "bastion_host_1" {
    ami           = "ami-0a91cd140a1fc148a"
    instance_type = "t2.micro"
    subnet_id     = aws_subnet.subnet_publica_1.id
    vpc_security_group_ids = [aws_security_group.sg_bastion.id]

    tags = {
        Name = "Bastion Host 1"
    }
}

resource "aws_instance" "bastion_host_2" {
    ami           = "ami-0a91cd140a1fc148a"
    instance_type = "t2.micro"
    subnet_id     = aws_subnet.subnet_publica_2.id
    vpc_security_group_ids = [aws_security_group.sg_bastion.id]

    tags = {
        Name = "Bastion Host 2"
    }
}

resource "aws_instance" "web_server_1" {
    ami           = "ami-0a91cd140a1fc148a"
    instance_type = "t2.micro"
    subnet_id     = aws_subnet.subnet_privada_1.id
    vpc_security_group_ids = [aws_security_group.sg_web.id]

    tags = {
        Name = "Web Server 1"
    }
}

resource "aws_instance" "web_server_2" {
    ami           = "ami-0a91cd140a1fc148a"
    instance_type = "t2.micro"
    subnet_id     = aws_subnet.subnet_privada_2.id
    vpc_security_group_ids = [aws_security_group.sg_web.id]

    tags = {
        Name = "Web Server 2"
    }
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