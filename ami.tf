resource "aws_instance" "my_ubuntu_instance" {
  ami                         = "ami-04b4f1a9cf54c11d0"
  instance_type               = "t2.small"
  key_name                    = "my_new_key"
  subnet_id                   = aws_subnet.public_subnet_1.id
  associate_public_ip_address = true
  security_groups             = [aws_security_group.web_sg.id]

  

  tags = {
    Name = "ecapp-group10-ubuntu-instance"
  }

  user_data = <<-EOF
        #!/bin/bash
        sudo apt update -y
        sudo apt install -y apache2 php libapache2-mod-php php-mysql git unzip mysql-client

        # Start and enable Apache
        sudo systemctl start apache2
        sudo systemctl enable apache2

        # Set up Apache Directory Index
        echo 'DirectoryIndex index.php index.html index.cgi index.pl index.xhtml index.htm' | sudo tee /etc/apache2/mods-enabled/dir.conf
        sudo systemctl restart apache2

        # Clone the latest code from GitHub
        git clone https://github.com/reubenthomas107/ecommerce-app-grp10.git /tmp/ecapp
        sudo mv /tmp/ecapp/webapp/* /var/www/html

        # Fetch Database Credentials Securely
        DB_PASS=$(aws ssm get-parameter --name "/ecapp/dbpassword" --with-decryption --query "Parameter.Value" --output text)
        DB_HOST="${aws_db_instance.mysql.endpoint}"

        echo "export DB_PASS=$DB_PASS" | sudo tee -a /etc/environment
        echo "export DB_HOST=$DB_HOST" | sudo tee -a /etc/environment
        source /etc/environment

        # Configure the application database connection dynamically
        sudo sed -i "s/HARDCODED_DB_HOST/$DB_HOST/g" /var/www/html/connect.php
        sudo sed -i "s/HARDCODED_DB_PASSWORD/$DB_PASS/g" /var/www/html/connect.php

        # Import the MySQL database schema
        mysql -h $DB_HOST -u ecappadmin -p$DB_PASS ecommerce_1 < /tmp/ecapp/database/ecommerce_1.sql

        # Clean up installation files
        sudo apt remove -y mysql-client
        rm -rf /tmp/ecapp

        # Restart Apache to apply changes
        sudo systemctl restart apache2
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