terraform {
  required_version = ">= 1.0"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

# ==================== VARIÁVEIS LOCAIS ====================
locals {
  project_name = "dsf"
  root_dir     = "${path.module}/.."
  
  container_names = {
    database = "${local.project_name}-database"
    backend  = "${local.project_name}-backend"
    frontend = "${local.project_name}-frontend"
    proxy    = "${local.project_name}-proxy"
  }
}

# ==================== VOLUMES & NETWORKS ====================
resource "docker_volume" "postgres_data" {
  name = "${local.project_name}-postgres-data"
}

resource "docker_network" "internal_network" {
  name     = "${local.project_name}-internal-network"
  driver   = "bridge"
  internal = true
  
  ipam_config {
    subnet = "10.10.0.0/24"
    gateway = "10.10.0.1"
  }
}

resource "docker_network" "external_network" {
  name   = "${local.project_name}-external-network"
  driver = "bridge"
  
  ipam_config {
    subnet = "10.10.1.0/24"
    gateway = "10.10.1.1"
  }
}

# ==================== IMAGENS ====================
resource "docker_image" "database" {
  name = "${local.project_name}-database-image"
  
  build {
    context    = "${local.root_dir}/database"
    dockerfile = "Dockerfile"
  }
  
  force_remove = true
}

resource "docker_image" "backend" {
  name = "${local.project_name}-backend-image"
  
  build {
    context    = "${local.root_dir}/backend"
    dockerfile = "Dockerfile"
  }
  
  force_remove = true
}

resource "docker_image" "frontend" {
  name = "${local.project_name}-frontend-image"
  
  build {
    context    = "${local.root_dir}/frontend"
    dockerfile = "Dockerfile"
  }
  
  force_remove = true
}

resource "docker_image" "proxy" {
  name = "${local.project_name}-proxy-image"
  
  build {
    context    = "${local.root_dir}/proxy"
    dockerfile = "Dockerfile"
  }
  
  force_remove = true
}

# ==================== CONTAINERS ====================
resource "docker_container" "database" {
  name  = local.container_names.database
  image = docker_image.database.image_id
  
  restart = "unless-stopped"
  
  env = [
    "POSTGRES_DB=${var.db_name}",
    "POSTGRES_USER=${var.db_user}",
    "POSTGRES_PASSWORD=${var.db_password}"
  ]
  
  healthcheck {
    test     = ["CMD-SHELL", "pg_isready -U ${var.db_user} -d ${var.db_name}"]
    interval = "30s"
    timeout  = "3s"
    retries  = 3
    start_period = "5s"
  }
  
  volumes {
    volume_name    = docker_volume.postgres_data.name
    container_path = "/var/lib/postgresql/data"
  }
  
  volumes {
    host_path      = "${abspath(local.root_dir)}/sql/script.sql"
    container_path = "/docker-entrypoint-initdb.d/init.sql"
  }
  
  networks_advanced {
    name = docker_network.internal_network.name
  }
  
  stop_timeout = 30
}

resource "docker_container" "backend" {
  name  = local.container_names.backend
  image = docker_image.backend.image_id
  
  restart = "always"
  
  env = [
    "PORT=3000",
    "DB_HOST=${docker_container.database.name}",
    "DB_PORT=5432",
    "DB_USER=${var.db_user}",
    "DB_PASSWORD=${var.db_password}",
    "DB_NAME=${var.db_name}"
  ]
  
  healthcheck {
    test     = ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:3000/health"]
    interval = "15s"
    timeout  = "5s"
    retries  = 1
    start_period = "30s"
  }
  
  networks_advanced {
    name = docker_network.internal_network.name
  }
  
  depends_on = [docker_container.database]
  stop_timeout = 30
}

resource "docker_container" "frontend" {
  name  = local.container_names.frontend
  image = docker_image.frontend.image_id
  
  restart = "unless-stopped"
  
  networks_advanced {
    name = docker_network.internal_network.name
  }
  
  depends_on = [docker_container.backend]
  stop_timeout = 10
}

resource "docker_container" "proxy" {
  name  = local.container_names.proxy
  image = docker_image.proxy.image_id
  
  restart = "unless-stopped"
  
  ports {
    internal = 80
    external = 8080
  }
  
  networks_advanced {
    name = docker_network.internal_network.name
  }
  
  networks_advanced {
    name = docker_network.external_network.name
  }
  
  depends_on = [docker_container.backend, docker_container.frontend]
  stop_timeout = 10
}