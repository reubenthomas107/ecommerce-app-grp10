# Create an instance profile for the EC2 instance
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "my_ec2_profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_instance" "my_ubuntu_instance" {
  ami                         = "ami-04b4f1a9cf54c11d0"
  instance_type               = "t2.small"
  key_name                    = "ecapp_keypair"
  subnet_id                   = aws_subnet.public_subnet_1.id
  associate_public_ip_address = true
  iam_instance_profile  = aws_iam_instance_profile.ec2_profile.name
  tags = {
    Name = "ecapp-group10-ubuntu-instance"
  }
  # Security group to allow SSH access
  security_groups = [aws_security_group.web_sg.id]
  user_data = <<-EOF
        #!/bin/bash
        sudo apt update -y
        sudo apt install -y apache2 php libapache2-mod-php php-mysql git unzip
        sudo snap install aws-cli --classic

        # Start and enable Apache
        sudo systemctl start apache2
        sudo systemctl enable apache2

        # Set up Apache Directory Index
        echo 'DirectoryIndex index.php index.html index.cgi index.pl index.xhtml index.htm' | sudo tee /etc/apache2/mods-enabled/dir.conf
        sudo systemctl restart apache2

        # Clone the latest code from GitHub
        git clone -b feature/cdn https://github.com/reubenthomas107/ecommerce-app-grp10.git /tmp/ecapp
        sudo mv /tmp/ecapp/webapp/* /var/www/html

        # Fetch Database Credentials Securely
        DB_PASS=$(aws ssm get-parameter --name "/ecapp/db/password" --with-decryption --query "Parameter.Value" --output text)
        DB_HOST="${aws_db_instance.mysql.address}"
        ECAPP_CDN_URL="${vars.cdn_url}" #TODO: Temp CDN URL

        echo "export DB_PASS=$DB_PASS" | sudo tee -a /etc/environment
        echo "export DB_HOST=$DB_HOST" | sudo tee -a /etc/environment
        echo "export ECAPP_CDN_URL=$ECAPP_CDN_URL" | sudo tee -a /etc/environment
        source /etc/environment

        # Configure the application database connection dynamically
        sudo sed -i "s/DB_HOST_VALUE/$DB_HOST/g" /var/www/html/includes/connect.php
        sudo sed -i "s/DB_PASSWORD_VALUE/$DB_PASS/g" /var/www/html/includes/connect.php

        #Configure CDN Endpoint for Static Resources
        find . -type f \( -name "*.css" -o -name "*.php" \) -exec sudo sed -i "s|ECAPP_CDN_ENDPOINT_URL|$ECAPP_CDN_URL|g" {} +

        # Clean up installation files
        rm -rf /tmp/ecapp
        sudo rm -rf /var/www/html/index.html

        # Restart Apache to apply changes
        sudo systemctl restart apache2
        EOF 

  root_block_device {
    volume_size = 10
    volume_type = "gp3"
  }

  lifecycle {
    ignore_changes = [
      security_groups
    ]
  }
}

# resource "time_sleep" "wait-ubuntu" {
#   create_duration = "200s"
#   depends_on      = [aws_instance.my_ubuntu_instance]
# }

# resource "aws_ami_from_instance" "ecapp-websv-ami" {
#   name               = "ecapp-websv-ami"
#   source_instance_id = aws_instance.my_ubuntu_instance.id
#   depends_on         = [time_sleep.wait-ubuntu]

#   lifecycle {
#     ignore_changes = [
#       source_instance_id
#     ]
#   }
# }



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


