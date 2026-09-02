resource "aws_db_subnet_group" "std17_rds_subnet_group" {
    name       = "${var.name_prefix}-db-subnet-group"
    subnet_ids = var.private_subnet_ids
    tags = {
        Name = "${var.name_prefix}-db-subnet-group"
    }
}

# ==================================================================
# 보안 암호 (Secrets Manager)
resource "random_password" "std17_mysql_master" {
    length  = 20
    special = false
}

resource "aws_secretsmanager_secret" "std17_mysql_master" {
    name = "${var.name_prefix}-rds-master-secret"
    tags = {
        Name = "${var.name_prefix}-rds-master-secret"
    }
}

resource "aws_secretsmanager_secret_version" "std17_mysql_master" {
    secret_id = aws_secretsmanager_secret.std17_mysql_master.id
    secret_string = jsonencode({
        username = var.master_username
        password = random_password.std17_mysql_master.result
    })
}

# ==================================================================
# RDS 인스턴스
resource "aws_db_instance" "std17_mysql" {
    identifier              = "${var.name_prefix}-mysql"
    engine                  = "mysql"
    engine_version          = "8.4.10"
    instance_class          = "db.t4g.micro"
    allocated_storage       = 20
    db_name                 = var.db_name
    username                = var.master_username
    password                = random_password.std17_mysql_master.result
    db_subnet_group_name    = aws_db_subnet_group.std17_rds_subnet_group.name
    vpc_security_group_ids  = [var.security_group_id]
    publicly_accessible     = false
    backup_retention_period = 0
    skip_final_snapshot     = true

    tags = {
        Name = "${var.name_prefix}-mysql"
    }
}

# ==================================================================
# RDS Proxy
resource "aws_iam_role" "std17_mysql_proxy_role" {
    name = "${var.name_prefix}-rds-proxy-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Effect    = "Allow"
            Principal = { Service = "rds.amazonaws.com" }
            Action    = "sts:AssumeRole"
        }]
    })

    tags = {
        Name = "${var.name_prefix}-rds-proxy-role"
    }
}

resource "aws_iam_role_policy" "std17_mysql_proxy_secrets_access" {
    name = "${var.name_prefix}-rds-proxy-secrets-access"
    role = aws_iam_role.std17_mysql_proxy_role.id

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Effect   = "Allow"
            Action   = ["secretsmanager:GetSecretValue"]
            Resource = aws_secretsmanager_secret.std17_mysql_master.arn
        }]
    })
}

resource "aws_db_proxy" "std17_mysql_proxy" {
    name                   = "${var.name_prefix}-rds-proxy"
    engine_family          = "MYSQL"
    role_arn               = aws_iam_role.std17_mysql_proxy_role.arn
    vpc_subnet_ids         = var.private_subnet_ids
    vpc_security_group_ids = [var.security_group_id]

    auth {
        auth_scheme = "SECRETS"
        secret_arn  = aws_secretsmanager_secret.std17_mysql_master.arn
    }

    tags = {
        Name = "${var.name_prefix}-rds-proxy"
    }
}

resource "aws_db_proxy_default_target_group" "std17_mysql_proxy" {
    db_proxy_name = aws_db_proxy.std17_mysql_proxy.name

    connection_pool_config {
        max_connections_percent = 100
    }
}

resource "aws_db_proxy_target" "std17_mysql_proxy" {
    db_proxy_name          = aws_db_proxy.std17_mysql_proxy.name
    target_group_name      = aws_db_proxy_default_target_group.std17_mysql_proxy.name
    db_instance_identifier = aws_db_instance.std17_mysql.identifier
}