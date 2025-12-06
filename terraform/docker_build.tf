# ==================== BUILD DE IMAGENS DOCKER PARA MINIKUBE ====================
# Este arquivo define recursos para construir imagens Docker
# diretamente no Docker daemon do Minikube.

# Recurso para construir a imagem do Backend
resource "docker_image" "backend_image" {
  name = "backend:latest"
  build {
    context    = "${path.module}/../backend"
    dockerfile = "Dockerfile"
    platform   = "linux/amd64" # Garante compatibilidade com o cluster DOKS
  }
  keep_locally = true # Mantém a imagem localmente para o Minikube
}

# Recurso para construir a imagem do Frontend
resource "docker_image" "frontend_image" {
  name = "frontend:latest"
  build {
    context    = "${path.module}/../frontend"
    dockerfile = "Dockerfile"
    platform   = "linux/amd64" # Garante compatibilidade com o cluster DOKS
  }
  keep_locally = true # Mantém a imagem localmente para o Minikube
}

# Recurso para construir a imagem do Proxy
resource "docker_image" "proxy_image" {
  name = "proxy:latest"
  build {
    context    = "${path.module}/../proxy"
    dockerfile = "Dockerfile"
    platform   = "linux/amd64" # Garante compatibilidade com o cluster DOKS
  }
  keep_locally = true # Mantém a imagem localmente para o Minikube
}

# Recurso para construir a imagem do Banco de Dados
resource "docker_image" "database_image" {
  name = "postgres:latest" # Usar um nome de imagem consistente
  build {
    context    = "${path.module}/../database"
    dockerfile = "Dockerfile"
    platform   = "linux/amd64"
  }
  keep_locally = true
}