output "invoke_arn" {
    description = "API Gateway 통합용 Lambda invoke ARN"
    value       = aws_lambda_function.std17_student_lookup.invoke_arn
}

output "function_name" {
    description = "Lambda 함수 이름"
    value       = aws_lambda_function.std17_student_lookup.function_name
}