#!/bin/bash
echo "⚠️  LIMPEZA TOTAL DO DOCKER ⚠️"
echo "Esta operação removerá:"
echo "- Todos os containers (rodando e parados)"
echo "- Todas as imagens"
echo "- Todos os volumes"
echo "- Todas as redes personalizadas"
echo ""
read -p "Tem certeza? (s/N): " confirm

if [[ $confirm == [sS] ]]; then
    echo "Parando containers..."
    docker stop $(docker ps -aq) 2>/dev/null || true
    
    echo "Removendo containers..."
    docker rm $(docker ps -aq) 2>/dev/null || true
    
    echo "Removendo imagens..."
    docker rmi -f $(docker images -aq) 2>/dev/null || true
    
    echo "Removendo volumes..."
    docker volume rm $(docker volume ls -q) 2>/dev/null || true
    
    echo "Removendo redes..."
    docker network rm $(docker network ls -q | grep -v "bridge\|host\|none") 2>/dev/null || true
    
    echo "Limpando sistema..."
    docker system prune -a --volumes -f
    
    echo "✅ Limpeza completa!"
else
    echo "Operação cancelada."
fi