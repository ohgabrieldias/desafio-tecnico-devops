variable "db_name" {
  description = "Nome do banco de dados PostgreSQL"
  type        = string
  default     = "desafio_db"
}

variable "db_user" {
  description = "Usuário do banco de dados"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "Senha do banco de dados"
  type        = string
  sensitive   = true
  default     = "password"
}

variable "backend_port" {
  description = "Porta do backend"
  type        = number
  default     = 3000
}

variable "proxy_port" {
  description = "Porta do proxy (externa)"
  type        = number
  default     = 8080
}