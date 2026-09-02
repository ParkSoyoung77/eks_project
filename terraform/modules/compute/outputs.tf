output "asg_name" {
    description = "docker-compose EC2 오토스케일링 그룹 이름"
    value       = aws_autoscaling_group.std17_ec2_asg.name
}

output "deploy_bucket_name" {
    description = "배포 아티팩트 S3 버킷 이름"
    value       = aws_s3_bucket.std17_deploy_artifacts.id
}