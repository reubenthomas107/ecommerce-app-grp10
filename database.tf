resource "aws_ssm_parameter" "dbsecret" {
    name        = "/ecapp/dbpassword"
    description = "ECAPP DB Password"
    type        = "SecureString"
    value       = var.db_password
    overwrite   = true  # Ensures Terraform updates it if needed
}

resource "aws_ssm_parameter" "db_host" {
    name        = "/ecapp/db_host"
    description = "ECAPP DB Hostname (RDS Endpoint)"
    type        = "String"
    value       = aws_db_instance.mysql.address
    overwrite   = true
}

resource "aws_ssm_parameter" "db_username" {
    name        = "/ecapp/db_username"
    description = "ECAPP DB Username"
    type        = "String"
    value       = "ecappadmin"  # Matches the username used in RDS creation
    overwrite   = true
}

resource "aws_db_instance" "mysql" {
    allocated_storage    = 25
    max_allocated_storage = 100
    storage_type         = "gp2"
    engine              = "mysql"
    engine_version      = "8.0"
    multi_az = "false" # TODO: set as true later
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
