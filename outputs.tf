output "efs_id" {
  description = "EFS file system ID for Minecraft world data"
  value       = aws_efs_file_system.minecraft_data.id
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster running the Minecraft server"
  value       = aws_ecs_cluster.minecraft_server.name
}

output "vpc_id" {
  description = "VPC ID where the Minecraft server is deployed"
  value       = module.vpc.vpc_id
}

output "next_step" {
  description = "Instructions to find the server public IP"
  value       = "Once the service is Running, find the public IP in the ECS console or use the AWS CLI."
}