output "efs_id" {
  value = aws_efs_file_system.minecraft_data.id
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.minecraft_server.name
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "next_step" {
  value = "Una vez que el servicio esté 'Running', busca la IP pública en la consola de ECS o usa la CLI."
}