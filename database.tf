resource "aws_ssm_parameter" "dbsecret" {
    name        = "/ecapp/dbpassword"
    description = "ECAPP DB Password"
    type        = "SecureString"
    value       = var.db_password
}

resource "aws_db_instance" "mysql" {
    allocated_storage    = 25
    max_allocated_storage = 100
    storage_type         = "gp2"
    engine              = "mysql"
    engine_version      = "8.0"
    multi_az = "false" #TODO: set as true later
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

# resource "null_resource" "import_sql" {
#   provisioner "local-exec" {
#     command = <<EOT
#       mysql -h ${aws_db_instance.mysql.address} -u ecappadmin -p${var.db_password} ecommerce_1 < ./database/ecommerce_1.sql
#     EOT
#   }

#   depends_on = [aws_db_instance.mysql]
# }


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