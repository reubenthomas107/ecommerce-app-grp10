resource "aws_ssm_parameter" "dbsecret" {
    name        = "/ecapp/db/password"
    description = "ECAPP DB Password"
    type        = "SecureString"
    value       = var.db_password
}

resource "aws_ssm_parameter" "dburl" {
    name        = "/ecapp/db/url"
    description = "ECAPP DB Endpoint"
    type        = "SecureString"
    value       = aws_db_instance.mysql.address
}


resource "aws_db_instance" "mysql" {
    allocated_storage    = 25
    max_allocated_storage = 100
    storage_type         = "gp2"
    engine              = "mysql"
    engine_version      = "8.0"
    multi_az = "true"
    instance_class      = "db.t3.micro"
    identifier         = "ecapp-db"
    username           = "ecappadmin"
    password           = var.db_password
    parameter_group_name = "default.mysql8.0"
    db_name = "ecommerce_1"
    vpc_security_group_ids = [aws_security_group.db_sg.id]
    db_subnet_group_name = aws_db_subnet_group.main.id
    publicly_accessible = "false"
    storage_encrypted = "true"
    skip_final_snapshot = "true"
    backup_retention_period  = 7      
    backup_window            = "05:00-06:00" 
    apply_immediately        = true  
    
}

# Create a new EC2 instance to import the database (initial setup)
resource "aws_instance" "my_db_setup_instance" {
  ami                         = "ami-04b4f1a9cf54c11d0"
  instance_type               = "t2.small"
  key_name                    = "ecapp_keypair"
  subnet_id                   = aws_subnet.public_subnet_1.id
  associate_public_ip_address = true
  iam_instance_profile  = aws_iam_instance_profile.ec2_profile.name
  tags = {
    Name = "ecapp-group10-db-setup-instance"
  }
  # Security group to allow SSH access
  security_groups = [aws_security_group.web_sg.id]
  user_data = <<-EOF
        #!/bin/bash
        sudo apt update -y
        sudo apt install -y git unzip mysql-client
        
        # Clone the latest code from GitHub
        git clone https://github.com/reubenthomas107/ecommerce-app-grp10.git /tmp/ecapp
        
        # Import the MySQL database schema
        mysql -h ${aws_db_instance.mysql.address} -u ecappadmin -p${var.db_password} ecommerce_1 < /tmp/ecapp/database/ecommerce_1.sql

        # Clean up installation files
        rm -rf /tmp/ecapp
        EOF 

  root_block_device {
    volume_size = 10
    volume_type = "gp3"
  }
}

resource "time_sleep" "wait" {
  create_duration = "200s"
  depends_on      = [aws_instance.my_db_setup_instance]
}

resource "null_resource" "delete_setup_ec2_instance" {
  provisioner "local-exec" {
    command = "terraform destroy -target=aws_instance.my_db_setup_instance -auto-approve"
  }
  depends_on = [time_sleep.wait]
}


resource "aws_db_subnet_group" "main" {
    name       = "main"
    subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
}

output "database_url" {
    description = "Database address"
    value = aws_db_instance.mysql.address
}

output "database_name" {
    description = "Database Name"
    value = aws_db_instance.mysql.db_name
}

output "database_private_ip" {
    description = "Database Endpoint"
    value = aws_db_instance.mysql.endpoint
}