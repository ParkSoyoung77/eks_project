# ==================================================================
# Lambda Layer (pymysql) - 로컬에서 미리 빌드한 zip을 그대로 업로드
resource "aws_lambda_layer_version" "std17_pymysql_layer" {
    filename            = "${path.module}/pymysql-layer.zip"
    layer_name          = "${var.name_prefix}-pymysql-layer"
    compatible_runtimes = ["python3.14"]
    source_code_hash    = filebase64sha256("${path.module}/pymysql-layer.zip")
}

# ==================================================================
# Lambda 함수 코드 (순수 소스만, pymysql 제외)
data "archive_file" "std17_student_lookup_zip" {
    type        = "zip"
    source_dir  = "${path.module}/lambda"
    output_path = "${path.module}/build/student_lookup.zip"
    excludes    = ["requirements.txt"]
}

# ==================================================================
# IAM 역할 / 권한
resource "aws_iam_role" "std17_lambda_role" {
    name = "${var.name_prefix}-lambda-student-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Effect    = "Allow"
            Principal = { Service = "lambda.amazonaws.com" }
            Action    = "sts:AssumeRole"
        }]
    })

    tags = {
        Name = "${var.name_prefix}-lambda-student-role"
    }
}

resource "aws_iam_role_policy_attachment" "std17_lambda_vpc_access" {
    role       = aws_iam_role.std17_lambda_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy" "std17_lambda_secrets_access" {
    name = "${var.name_prefix}-lambda-secrets-access"
    role = aws_iam_role.std17_lambda_role.id

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Sid      = "Statement1"
            Effect   = "Allow"
            Action   = ["secretsmanager:GetSecretValue"]
            Resource = var.db_secret_arn
        }]
    })
}

# ==================================================================
# Lambda 함수
resource "aws_cloudwatch_log_group" "std17_student_lookup" {
    name              = "/aws/lambda/${var.name_prefix}-student-lookup"
    retention_in_days = 7
}

resource "aws_lambda_function" "std17_student_lookup" {
    function_name = "${var.name_prefix}-student-lookup"
    role          = aws_iam_role.std17_lambda_role.arn

    filename         = data.archive_file.std17_student_lookup_zip.output_path
    source_code_hash = data.archive_file.std17_student_lookup_zip.output_base64sha256

    handler = "lambda-student.lambda_handler"
    runtime = "python3.14"
    timeout = 10

    layers = [aws_lambda_layer_version.std17_pymysql_layer.arn]

    vpc_config {
        subnet_ids         = var.private_subnet_ids
        security_group_ids = [var.security_group_id]
    }

    environment {
        variables = {
            DB_SECRET_NAME = var.db_secret_arn
            DB_HOST        = var.db_host
            DB_NAME        = var.db_name
            DB_PORT        = "3306"
        }
    }

    depends_on = [
        aws_iam_role_policy_attachment.std17_lambda_vpc_access,
        aws_iam_role_policy.std17_lambda_secrets_access,
        aws_cloudwatch_log_group.std17_student_lookup,
    ]

    tags = {
        Name = "${var.name_prefix}-student-lookup"
    }
}