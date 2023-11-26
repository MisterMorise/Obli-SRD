resource "aws_key_pair" "key_pair" {
  key_name   = "id_rsa.pub"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCzMeLrNAK40kahNSY5MVQ3dIKeHqWXD/uXrkL6dUmW/R7q4FUfgpUESAfPLQVbw+UVtvJcNjVe6OTZk3U4S7L0J0vRw6U+LClYJmqOV62HePDiD2/Xvs6AAhf4Kh+E3ExjBI8afRQQFnGXjeV25OULeRk4vcc2PBgPMJj3yw88Ld6qWpca2OCQ0bSKFv5tYm4/ZnHC9KcFTPjCpErxDTa2S6TvtZ0jmhthBdw9TEJuTA3YxLOXBTUUPJ9nm9YDXycAMzTnhCtgsTzXLYAN902xmT2aZndGKpKAdduVaxpULOGMGzSuZ930prohrA21lz5fTYrgq4iSHBs1OtS9DYZ4Q1xwo39bHbbeqnscEV0Q8YGOt4S+sH8wUbWR5uHdgzYHqw8uVqtwnzo03jpk7O8AFMuNnL54CQZUEurhpE6il8PbGlvFCF+E9N+uQUlRaBTUCMGccbm9Vid6VizJZNCmQvBPoS4pRlvW6NavA/OHfblBi2BsC7VP6RclwQT7Ikc= srd@obli-srd"
}

resource "aws_instance" "bastion" {
    ami           = "ami-0fc5d935ebf8bc3bc"
    instance_type = "t2.micro"
    key_name      = aws_key_pair.key_pair.key_name
    subnet_id     = aws_subnet.subnet_publica.id
    vpc_security_group_ids = [aws_security_group.sg_bastion.id]

    tags = {
        Name = "Bastion"
    }
}

resource "aws_instance" "webserver" {
    ami           = "ami-0fc5d935ebf8bc3bc"
    instance_type = "t2.micro"
    key_name      = aws_key_pair.key_pair.key_name
    subnet_id     = aws_subnet.subnet_publica.id
    vpc_security_group_ids = [aws_security_group.sg_web.id]

    user_data = <<-EOF
                            #!/bin/bash
                            sudo apt update -y
                            sudo apt install apache2 -y
                            sudo systemctl enable apache2
                            sudo systemctl start apache2
                            sudo apt install mysql-server php libapache2-mod-php php-mysql -y
                            wget https://wordpress.org/latest.tar.gz
                            tar xzvf latest.tar.gz
                            sudo cp -R wordpress/* /var/www/html/
                            EOF

    tags = {
        Name = "WebServer"
    }
}

resource "aws_db_instance" "WP_DB" {
    allocated_storage    = 20
    storage_type         = "gp2"
    engine               = "mysql"
    engine_version       = "5.7"
    instance_class       = "db.t2.micro"
    identifier           = "srd"
    username             = "Obli.SRD"
    password             = "Obli.SRD-2023"
    parameter_group_name = "default.mysql5.7"
    vpc_security_group_ids = [aws_security_group.sg_rds.id]
    db_subnet_group_name = "db_subnet_group" 

    tags = {
        Name = "WP_DB"
    }
}

resource "null_resource" "configurar_wordpress" {
    depends_on = [aws_instance.webserver, aws_db_instance.WP_DB]

    provisioner "remote-exec" {
        inline = [
            "sudo sed -i 's/database_name_here/srd/g' /var/www/html/wp-config.php",
            "sudo sed -i 's/username_here/Obli.SRD/g' /var/www/html/wp-config.php",
            "sudo sed -i 's/password_here/Obli.SRD-2023/g' /var/www/html/wp-config.php",
            "sudo sed -i 's/localhost/${aws_db_instance.WP_DB.endpoint}/g' /var/www/html/wp-config.php"
        ]

        connection {
            type        = "ssh"
            user        = "ubuntu"
            private_key = file("~/.ssh/id_rsa")
            host        = aws_instance.webserver.public_ip
        }
    }
}