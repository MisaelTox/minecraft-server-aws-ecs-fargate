variable "region" {
  description = "AWS region where the Minecraft server will be deployed"
  type        = string
  default     = "eu-north-1"
}

variable "minecraft_version" {
  description = "Minecraft server version (itzg/minecraft-server image tag)"
  type        = string
  default     = "1.21.3"
}

variable "cpu" {
  description = "Fargate CPU units (1024 = 1 vCPU)"
  type        = string
  default     = "1024"
}

variable "memory" {
  description = "Fargate memory in MB (2048 = 2GB)"
  type        = string
  default     = "2048"
}