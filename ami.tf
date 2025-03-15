resource "aws_instance" "my_ubuntu_instance" {
  ami                         = "ami-04b4f1a9cf54c11d0"
  instance_type               = "t2.small"
  key_name                    = "ecapp_keypair"
  subnet_id                   = aws_subnet.public_subnet_1.id
  associate_public_ip_address = true
  tags = {
    Name = "ecapp-group10-ubuntu-instance"
  }
  # Security group to allow SSH access
  security_groups = [aws_security_group.web_sg.id]
  user_data = <<-EOF
        #!/bin/bash
        sudo apt update -y
        sudo apt install apache2 -y
        sudo systemctl start apache2
        sudo systemctl enable apache2
        sudo apt install php libapache2-mod-php php-mysql -y
        echo 'DirectoryIndex index.php index.html index.cgi index.pl index.xhtml index.htm' | sudo tee /etc/apache2/mods-enabled/dir.conf
        sudo systemctl restart apache2
        git clone https://github.com/reubenthomas107/ecommerce-app-grp10.git /tmp/ecapp
        sudo mv /tmp/ecapp/webapp/* /var/www/html
        
        #TODO: DATABASE and HOST VARIABLE NOT POPULATING WITHIN connect.php
        echo 'export DB_PASS=${var.db_password}' >> /etc/environment
        echo 'export DB_HOST=${aws_db_instance.mysql.address}' >> /etc/environment
        
        #DB import is working
        sudo apt install mysql-client -y
        mysql -h ${aws_db_instance.mysql.address} -u ecappadmin -p${var.db_password} ecommerce_1 < /tmp/ecapp/database/ecommerce_1.sql
        sudo apt remove mysql-client -y
        rm -rf /tmp/ecapp
        EOF 

  root_block_device {
    volume_size = 10
    volume_type = "gp3"
  }
}

output "instance_public_ip" {
  description = "The public IP address of the EC2 instance"
  value       = aws_instance.my_ubuntu_instance.public_ip
}

output "web_server_url" {
  description = "The URL to access the web server on the EC2 instance"
  value       = "http://${aws_instance.my_ubuntu_instance.public_ip}"
}

output "new_app_ecomm_web_url" {
  description = "The URL to access the web server on the EC2 instance"
  value       = "http://${aws_instance.my_ubuntu_instance.public_ip}/index.php"
}