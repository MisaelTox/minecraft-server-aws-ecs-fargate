variable "region" {
  description = "Región de AWS para desplegar el servidor"
  type        = string
  default     = "eu-north-1"
}

variable "minecraft_version" {
  description = "Versión de Minecraft (etzg/minecraft-server)"
  type        = string
  default     = "1.21.3"
}

variable "cpu" {
  description = "Unidades de CPU de Fargate (1024 = 1 vCPU)"
  type        = string
  default     = "1024"
}

variable "memory" {
  description = "Memoria de Fargate (2048 = 2GB)"
  type        = string
  default     = "2048"
}