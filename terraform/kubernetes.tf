# ==================== RECURSOS KUBERNETES (VIA MANIFESTOS YAML) ====================
# Este arquivo define recursos Kubernetes aplicando manifestos YAML diretamente.

resource "kubernetes_manifest" "desafio_devops_namespace" {
  manifest = yamldecode(file("${path.module}/../kubernetes/namespace.yaml")) # Assumindo que você tem um namespace.yaml
}

resource "kubernetes_manifest" "database_secret" {
  manifest = yamldecode(file("${path.module}/../kubernetes/database-secret.yaml"))
  depends_on = [
    kubernetes_manifest.desafio_devops_namespace
  ]
}

resource "kubernetes_manifest" "database_pvc" {
  manifest = yamldecode(file("${path.module}/../kubernetes/database-persistentvolumeclaim.yaml"))
  depends_on = [
    kubernetes_manifest.desafio_devops_namespace
  ]
}

resource "kubernetes_manifest" "database_deployment" {
  manifest = yamldecode(file("${path.module}/../kubernetes/database-deployment.yaml"))
  depends_on = [
    kubernetes_manifest.desafio_devops_namespace,
    kubernetes_manifest.database_secret,
    kubernetes_manifest.database_pvc
  ]
}

resource "kubernetes_manifest" "database_service" {
  manifest = yamldecode(file("${path.module}/../kubernetes/database-service.yaml"))
  depends_on = [
    kubernetes_manifest.desafio_devops_namespace,
    kubernetes_manifest.database_deployment
  ]
}

resource "kubernetes_manifest" "backend_configmap" {
  manifest = yamldecode(file("${path.module}/../kubernetes/backend-configmap.yaml"))
  depends_on = [
    kubernetes_manifest.desafio_devops_namespace,
    kubernetes_manifest.database_service # Backend depende do serviço do banco de dados
  ]
}

resource "kubernetes_manifest" "backend_deployment" {
  manifest = yamldecode(file("${path.module}/../kubernetes/backend-deployment.yaml"))
  depends_on = [
    kubernetes_manifest.desafio_devops_namespace,
    kubernetes_manifest.backend_configmap,
    kubernetes_manifest.database_secret,
    kubernetes_manifest.database_service,      # Service deve existir
    kubernetes_manifest.database_deployment,   # Deployment deve estar rodando
    kubernetes_manifest.database_pvc,          # PVC deve estar pronto
    kubernetes_manifest.database_secret,
    kubernetes_manifest.backend_configmap,
    docker_image.backend_image # Depende da imagem Docker ser construída
  ]
}

resource "kubernetes_manifest" "backend_service" {
  manifest = yamldecode(file("${path.module}/../kubernetes/backend-service.yaml"))
  depends_on = [
    kubernetes_manifest.desafio_devops_namespace,
    kubernetes_manifest.backend_deployment
  ]
}

resource "kubernetes_manifest" "frontend_deployment" {
  manifest = yamldecode(file("${path.module}/../kubernetes/frontend-deployment.yaml"))
  depends_on = [
    kubernetes_manifest.desafio_devops_namespace,
    docker_image.frontend_image # Depende da imagem Docker ser construída
  ]
}

resource "kubernetes_manifest" "frontend_service" {
  manifest = yamldecode(file("${path.module}/../kubernetes/frontend-service.yaml"))
  depends_on = [
    kubernetes_manifest.desafio_devops_namespace,
    kubernetes_manifest.frontend_deployment
  ]
}

resource "kubernetes_manifest" "proxy_configmap" {
  manifest = yamldecode(file("${path.module}/../kubernetes/proxy-configmap.yaml"))
  depends_on = [
    kubernetes_manifest.desafio_devops_namespace,
    kubernetes_manifest.backend_service, # Proxy depende do serviço do backend
    kubernetes_manifest.frontend_service # Proxy depende do serviço do frontend
  ]
}

resource "kubernetes_manifest" "proxy_deployment" {
  manifest = yamldecode(file("${path.module}/../kubernetes/proxy-deployment.yaml"))
  depends_on = [
    kubernetes_manifest.desafio_devops_namespace,
    kubernetes_manifest.proxy_configmap,
    docker_image.proxy_image # Depende da imagem Docker ser construída
  ]
}

resource "kubernetes_manifest" "proxy_service" {
  manifest = yamldecode(file("${path.module}/../kubernetes/proxy-service.yaml"))
  depends_on = [
    kubernetes_manifest.desafio_devops_namespace,
    kubernetes_manifest.proxy_deployment
  ]
}