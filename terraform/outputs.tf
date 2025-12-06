output "nginx_proxy_url" {
  description = "URL para acessar o Nginx Proxy (Minikube)"
  value       = "http://${local.minikube_ip}:30080" # Porta NodePort do serviço proxy
}

output "application_url" {
  description = "URL da aplicação (Frontend via Nginx Proxy)"
  value       = "http://${local.minikube_ip}:30080" # Porta NodePort do serviço proxy
}

output "api_url" {
  description = "URL da API do Backend (via Nginx Proxy)"
  value       = "http://${local.minikube_ip}:30080/api" # Porta NodePort do serviço proxy
}

output "deployment_summary" {
  description = "Resumo da implantação no Minikube"
  value = <<-EOT
  🎉 Implantação concluída no Minikube!

  🌐 Acesso à Aplicação:
  • Frontend: http://${local.minikube_ip}:30080
  • API:      http://${local.minikube_ip}:30080/api

  🔧 Para configurar o kubectl localmente (se ainda não o fez):
  minikube start
  minikube addons enable ingress
  eval $(minikube docker-env)
  
  EOT
  sensitive = true
}