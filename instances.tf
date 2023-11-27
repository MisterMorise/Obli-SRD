
resource "aws_instance" "bastion" {
  ami                    = "ami-0fc5d935ebf8bc3bc"
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.key_pair.key_name
  subnet_id              = aws_subnet.subnet_publica.id
  vpc_security_group_ids = [aws_security_group.sg_bastion.id]
  user_data              = <<-EOF
  #!/bin/bash
  # SSH Hardening
  sudo sed -i 's/#Port 22/Port 2939/' /etc/ssh/sshd_config
  sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
  sudo systemctl restart sshd
EOF

  tags = {
    Name = "Bastion"
  }
}

resource "aws_eip" "bastion" {
  instance = aws_instance.bastion.id
}

resource "aws_instance" "mysql" {
  ami                    = "ami-0fc5d935ebf8bc3bc"
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.key_pair.key_name
  subnet_id              = aws_subnet.subnet_privada.id
  private_ip             = "10.0.2.40"
  vpc_security_group_ids = [aws_security_group.sg_mysql.id]
  user_data              = <<-USERDATA
  #!/bin/bash
  # SSH Hardening
  sudo sed -i 's/#Port 22/Port 2939/' /etc/ssh/sshd_config
  sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
  sudo systemctl restart sshd

  sudo apt update -y
  sudo apt install mysql-server -y
  sudo systemctl start mysql
  sudo systemctl enable mysql

  # Crear base de datos para wp
  sudo mysql -e ALTER USER 'root'@'%' IDENTIFIED WITH mysql_native_password by 'S3gurid4d';
  sudo mysql -e "CREATE DATABASE wp;"
  sudo mysql -e "CREATE USER 'wp_user'@'%' IDENTIFIED BY 'Obli.SRD-2023';"
  sudo mysql -e "GRANT ALL PRIVILEGES ON wp.* TO 'wp_user'@'%';"
  sudo mysql -e "FLUSH PRIVILEGES;"
USERDATA
#PARA QUE MYSQL ACEPTE CONEXIONES EXTERNAS HAY QUE MODIFICAR EL ARCHIVO /etc/mysql/mysql.conf.d/mysqld.cnf Y CAMBIAR EL BIND
#ADDRESS DE 127.0.0.1 A 0.0.0.0, LUEGO REINICIAR EL SERVICIO CON sudo systemctl restart mysql
  tags = {
    Name = "MySQL"
  }

  depends_on = [
    aws_nat_gateway.nat, aws_route_table_association.as_tabla_ruta_privada
  ]
}

resource "aws_instance" "webserver" {
  ami                    = "ami-0fc5d935ebf8bc3bc"
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.key_pair.key_name
  subnet_id              = aws_subnet.subnet_publica.id
  vpc_security_group_ids = [aws_security_group.sg_web.id]
  user_data              = <<-EOF
    #!/bin/bash
    # SSH Hardening
    sudo sed -i 's/#Port 22/Port 2939/' /etc/ssh/sshd_config
    sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
    sudo systemctl restart sshd
    
    sudo apt update -y
    sudo apt install apache2 -y
    sudo systemctl enable apache2
    sudo systemctl start apache2
    sudo apt install mysql-server php libapache2-mod-php php-mysql -y
    wget https://wordpress.org/latest.tar.gz
    tar xzvf latest.tar.gz
    sudo mv wordpress/ /var/www/html/
    sudo systemctl restart apache2
    
    # Configura WordPress para usar MySQL server
    sudo sed -i "s/database_name_here/wp/g" /var/www/html/wordpress/wp-config-sample.php
    sudo sed -i "s/username_here/wp_user/g" /var/www/html/wordpress/wp-config-sample.php
    sudo sed -i "s/password_here/Obli.SRD-2023/g" /var/www/html/wordpress/wp-config-sample.php
    sudo sed -i "s/localhost/${aws_instance.mysql.private_ip}/g" /var/www/html/wordpress/wp-config-sample.php
    sudo mv /var/www/html/wordpress/wp-config-sample.php /var/www/html/wordpress/wp-config.php
    sudo systemctl restart apache2
EOF
#PARA QUE AL INGRESAR AL SERVIDOR WEB VIA NAVEGADOR Y QUE NOS MUESTRE LA PAGINA DE WORDPRESS HAY QUE MODIFICAR
#EL ARCHIVO /etc/apache2/sites-available/000-default.conf Y MODIFICAR LA LÍNEA DocumentRoot /var/www/html POR 
#DocumentRoot /var/www/html/wordpress, LUEGO REINICIAR EL SERVICIO CON sudo systemctl restart apache2
  tags = {
    Name = "WebServer"
  }

  depends_on = [
    aws_instance.mysql
  ]
}

resource "aws_eip" "webserver" {
  instance = aws_instance.webserver.id

  depends_on = [
    aws_instance.webserver
  ]
}

resource "aws_key_pair" "key_pair" {
  key_name   = "id_rsa.pub"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCzMeLrNAK40kahNSY5MVQ3dIKeHqWXD/uXrkL6dUmW/R7q4FUfgpUESAfPLQVbw+UVtvJcNjVe6OTZk3U4S7L0J0vRw6U+LClYJmqOV62HePDiD2/Xvs6AAhf4Kh+E3ExjBI8afRQQFnGXjeV25OULeRk4vcc2PBgPMJj3yw88Ld6qWpca2OCQ0bSKFv5tYm4/ZnHC9KcFTPjCpErxDTa2S6TvtZ0jmhthBdw9TEJuTA3YxLOXBTUUPJ9nm9YDXycAMzTnhCtgsTzXLYAN902xmT2aZndGKpKAdduVaxpULOGMGzSuZ930prohrA21lz5fTYrgq4iSHBs1OtS9DYZ4Q1xwo39bHbbeqnscEV0Q8YGOt4S+sH8wUbWR5uHdgzYHqw8uVqtwnzo03jpk7O8AFMuNnL54CQZUEurhpE6il8PbGlvFCF+E9N+uQUlRaBTUCMGccbm9Vid6VizJZNCmQvBPoS4pRlvW6NavA/OHfblBi2BsC7VP6RclwQT7Ikc= srd@obli-srd"
}
#SI DESEA CONECTARSE AL SERVIDOR WEB VIA SSH, DEBE MODIFICAR EL ATRIBUTO public_key CON SU LLAVE PÚBLICA
