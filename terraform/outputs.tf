output "application_url" {
  description = "URL da aplicação"
  value       = "http://localhost:8080"
}

output "api_url" {
  description = "URL da API"
  value       = "http://localhost:8080/api"
}

output "backend_health_url" {
  description = "URL do healthcheck do backend"
  value       = "http://localhost:3000/health"
}

output "deployment_summary" {
  description = "Resumo da implantação"
  value = <<-EOT
  🎉 Implantação concluída!
  
  📊 Serviços:
  • Database: ${docker_container.database.name}
  • Backend:  ${docker_container.backend.name} (porta: 3000)
  • Frontend: ${docker_container.frontend.name}
  • Proxy:    ${docker_container.proxy.name} (porta: 8080)
  
  🌐 Acesso:
  • Frontend: http://localhost:8080
  • API:      http://localhost:8080/api
  
  🔧 Teste:
  curl http://localhost:8080/api
  EOT
}