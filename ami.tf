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
        git clone https://github.com/reubenthomas107/ecommerce-app-grp10.git /tmp/ecapp
        sudo mv /tmp/ecapp/webapp/* /var/www/html

        # Fetch Database Credentials Securely
        DB_PASS=$(aws ssm get-parameter --name "/ecapp/db/password" --with-decryption --query "Parameter.Value" --output text)
        DB_HOST="${aws_db_instance.mysql.address}"
        ECAPP_CDN_URL="https://${aws_cloudfront_distribution.cdn.domain_name}"

        echo "export DB_PASS=$DB_PASS" | sudo tee -a /etc/environment
        echo "export DB_HOST=$DB_HOST" | sudo tee -a /etc/environment
        echo "export ECAPP_CDN_URL=$ECAPP_CDN_URL" | sudo tee -a /etc/environment
        source /etc/environment

        # Configure the application database connection dynamically
        sudo sed -i "s/DB_HOST_VALUE/$DB_HOST/g" /var/www/html/includes/connect.php
        sudo sed -i "s/DB_PASSWORD_VALUE/$DB_PASS/g" /var/www/html/includes/connect.php

        # Configure CDN Endpoint for Static Resources
        find /var/www/html -type f \( -name "*.css" -o -name "*.php" \) -exec sudo sed -i "s|ECAPP_CDN_ENDPOINT_URL|$ECAPP_CDN_URL|g" {} +

        # Clean up installation files
        rm -rf /tmp/ecapp
        sudo rm -rf /var/www/html/index.html

        # Changing directory ownership to low privileged user
        sudo chown -R www-data:www-data /var/www/html

        # Restart Apache to apply changes
        sudo systemctl restart apache2

        # Setting up cron job for s3 file sync
        sudo bash -c 'cat <<EOT > /opt/sync_script.sh
        #!/bin/bash
        LOG_FILE="/var/log/s3_sync.log"
        aws s3 sync /var/www/html/admin/admin_images/ s3://ecapp-webapp-bucket/admin_images/ --size-only &>> "\$LOG_FILE"
        aws s3 sync /var/www/html/admin/product_images/ s3://ecapp-webapp-bucket/product_images/ --size-only &>> "\$LOG_FILE"
        aws s3 sync /var/www/html/users_area/user_images/ s3://ecapp-webapp-bucket/user_images/ --size-only &>> "\$LOG_FILE"
        aws s3 sync /var/www/html/assets/ s3://ecapp-webapp-bucket/assets/ --size-only --exclude ".DS_Store" &>> "\$LOG_FILE"
        echo "\$(date): S3 Sync Completed" >> "\$LOG_FILE"
        EOT'
        
        # Setting execute permission and adding to cron (sync with s3 every 5 minutes)
        sudo chmod +x /opt/sync_script.sh
        (sudo crontab -l 2>/dev/null; echo "*/5 * * * * /opt/sync_script.sh") | sudo crontab -

        # Installing CA SSL certificate for Database Transit Encryption
        sudo mkdir -p /etc/mysql/ssl
        sudo wget -O /etc/mysql/ssl/rds-combined-ca-bundle.pem https://s3.amazonaws.com/rds-downloads/rds-combined-ca-bundle.pem


        # Configure CloudWatch Agent
        sudo wget -P /tmp https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
        sudo dpkg -i /tmp/amazon-cloudwatch-agent.deb
        sudo bash -c 'cat <<EOT > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
        {
          "logs": {
            "logs_collected": {
              "files": {
              "collect_list": [
                {
                "file_path": "/var/log/apache2/access.log",
                "log_group_name": "ecapp-web-logs/apache-access-logs",
                "log_stream_name": "{instance_id}"
                },
                {
                "file_path": "/var/log/apache2/error.log",
                "log_group_name": "ecapp-web-logs/apache-error-logs",
                "log_stream_name": "{instance_id}"
                }
              ]
              }
            }
          }
        }
        EOT'

        # Start the CloudWatch Agent
        sudo amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s
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

  depends_on = [ aws_cloudfront_distribution.cdn ]
}

resource "time_sleep" "wait-ubuntu" {
  create_duration = "100s"
  depends_on      = [aws_instance.my_ubuntu_instance]
}

resource "aws_ami_from_instance" "ecapp-websv-ami" {
  name               = "ecapp-websv-ami"
  source_instance_id = aws_instance.my_ubuntu_instance.id
  depends_on         = [time_sleep.wait-ubuntu]

  lifecycle {
    ignore_changes = [
      source_instance_id
    ]
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


