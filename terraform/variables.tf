# Variáveis para a aplicação (se necessário, podem ser usadas para ConfigMaps/Secrets)
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