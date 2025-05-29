variable "yc_token" {
  description = "Yandex Cloud OAuth token"
  type        = string
  sensitive   = true
}

variable "yc_cloud_id" {
  description = "Yandex Cloud ID"
  type        = string
  sensitive   = true
}

variable "yc_folder_id" {
  description = "Yandex Cloud Folder ID"
  type        = string
  sensitive   = true
}

variable "project_id" {
  description = "Project identifier for unique resource naming"
  type        = string
  default     = "todolist-prod"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "ssh_public_key" {
  description = "Path to SSH public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "ssh_private_key" {
  description = "Path to SSH private key"
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "docker_image" {
  description = "Docker image for backend"
  type        = string
  default     = "cr.yandex/crp9otn5ftpiojs9kvlc/todolist-backend:latest"
}

variable "yc_iam_token" {
  description = "Yandex Cloud IAM token for Docker auth"
  type        = string
  sensitive   = true
}


