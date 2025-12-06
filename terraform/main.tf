terraform {
  required_version = ">= 1.0"
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    docker = {
      source = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {
  host = "tcp://192.168.49.2:2376"
  cert_path = "/home/gabriel.dias/.minikube/certs"
}

provider "kubernetes" {
      config_path = "~/.kube/config"
}

# ==================== VARIÁVEIS LOCAIS ====================
locals {
  project_name = "desafio-devops" # Nome do projeto para o cluster e recursos
  root_dir     = "${path.module}/.."
  minikube_ip  = "192.168.49.2" # IP do Minikube obtido anteriormente
}
