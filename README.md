# 🛠️ Desafio Técnico DevOps - Infraestrutura como Código

Este projeto implementa uma aplicação web completa (frontend, backend, banco de dados) utilizando **Docker** e **Terraform** para orquestração de containers. A infraestrutura é definida como código, permitindo deploy consistente e reproduzível.

---

# 🏗️ Arquitetura
```
┌───────────────────────────────────────────────────────────┐
│                    Usuário Final                          │
│                     (Porta 8080)                          │
└───────────────────────┬───────────────────────────────────┘
                        │
+-----------------------------------------------------+
|                                                     |
|                🌐 REDE_EXTERNA                      |
|                  10.10.1.0/24                       |
|                                                     |
|                ┌───────▼────────┐                   |
|                │  Nginx Proxy   │                   |
|                │ IP: 10.10.1.x  │                   |
|                └───────┬────────┘                   |
|                        │                            |
+-----------------------------------------------------+
                         |
                         |
+-----------------------------------------------------+
|                        |                            |
|  🔒 REDE_INTERNA       |                            |
|    10.10.0.0/24        |                            |
|                        |                            |
|        ┌───────────────┼───────────────┐            |
|        │               │               │            |      
|  ┌───────▼─────┐ ┌──────▼──────┐ ┌──────▼──────┐    |
|  │   Frontend  │ │   Backend   │ │  Database   │    | 
|  │   (React)   │ │  (Node.js)  │ │ (PostgreSQL)│    |
|  │IP: 10.10.0.x| │IP: 10.10.0.x| │IP: 10.10.0.x|    |
|  └─────────────┘ └─────────────┘ └─────────────┘    |
|                                                     |
+-----------------------------------------------------+
```


## 📁 Estrutura do Projeto
```
desafio-tecnico-devops/
├── backend/
│   ├── Dockerfile
│   ├── index.js
│   ├── package.json
│   └── package-lock.json
├── database/
│   └── Dockerfile
├── frontend/
│   ├── Dockerfile
│   └── index.html
├── proxy/
│   ├── Dockerfile
│   └── nginx.conf
├── sql/
│   └── script.sql
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars
├── docker-compose.yml
├── clean-docker.sh
└── README.md
```

## 🛠️ Pré-requisitos

Antes de iniciar, certifique-se de ter instalado:

- **Docker** (versão 29.1.2 ou superior)
- **Terraform** (versão 1.0 ou superior) 
- **Git** para clonar o repositório

## 🔧 Instalação de Dependências (Windows)

Siga os passos abaixo no seu sistema operacional Windows.

### 1. Docker Desktop

O Docker é necessário para construir e executar imagens.

1.  **Baixe o Instalador:**
    * [Docker Desktop Installer.exe](https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe)
2.  **Instale:**
    * Execute o arquivo e siga o assistente de instalação.
    * **Reinicie o computador** após a instalação.
3.  **Verifique a Instalação:**
    ```bash
    docker --version
    ```
    *(Este comando deve retornar a versão do Docker.)*

### 2. Terraform

O Terraform é usado para gerenciar a infraestrutura.

1.  **Instale via Chocolatey (Recomendado):**
    * Se você não tem o Chocolatey (gerenciador de pacotes), instale-o primeiro.
    * Execute o comando no terminal:
        ```bash
        choco install terraform
        ```
2.  **Verifique a Instalação:**
    ```bash
    terraform --version
    ```
### 🐧 Para SO Linux (Ubuntu/Debian)

#### 1. Docker Engine

O Docker é instalado usando os pacotes oficiais.

1.  **Instale os Pacotes Necessários e o GPG Key do Docker:**
    ```bash
    sudo apt-get update
    sudo apt-get install ca-certificates curl gnupg
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL [https://download.docker.com/linux/ubuntu/gpg](https://download.docker.com/linux/ubuntu/gpg) | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    ```
2.  **Adicione o Repositório do Docker:**
    ```bash
    echo \
      "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] [https://download.docker.com/linux/ubuntu](https://download.docker.com/linux/ubuntu) \
      "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    ```
3.  **Instale o Docker:**
    ```bash
    sudo apt-get update
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    ```
4.  **Verifique:**
    ```bash
    docker --version
    ```
    *Para usar o Docker sem `sudo`, adicione seu usuário ao grupo `docker`: `sudo usermod -aG docker $USER` e reinicie a sessão.*

#### 2. Terraform

O Terraform é instalado usando o repositório oficial da HashiCorp.

1.  **Instale os Pacotes Necessários e o GPG Key do Terraform:**
    ```bash
    sudo apt-get update
    sudo apt-get install -y software-properties-common curl
    curl -fsSL [https://apt.releases.hashicorp.com/gpg](https://apt.releases.hashicorp.com/gpg) | sudo apt-key add -
    ```
2.  **Adicione o Repositório do HashiCorp:**
    ```bash
    sudo apt-add-repository "deb [arch=amd64] [https://apt.releases.hashicorp.com](https://apt.releases.hashicorp.com) $(lsb_release -cs) main"
    ```
3.  **Instale o Terraform:**
    ```bash
    sudo apt-get update
    sudo apt-get install terraform
    ```
4.  **Verifique:**
    ```bash
    terraform --version
    ```
---
## 🏃 Como Executar o Projeto

Siga os passos abaixo no terminal:

### 1️⃣ Clone o Repositório

Baixe o código-fonte:

```bash
git clone [https://github.com/ohgabrieldias/desafio-tecnico-devops.git](https://github.com/ohgabrieldias/desafio-tecnico-devops.git)
cd desafio-tecnico-devops
```

### 2️⃣ Inicialize o Terraform
Acesse a pasta de configuração e prepare o ambiente:
```bash
cd terraform
terraform init
```

### 3️⃣ Revise o Plano de Execução (Opcional)
Verifique quais recursos serão criados:
```bash
terraform plan
```
### 4️⃣ Execute a Infraestrutura
Crie e inicie os recursos (Docker, Redes, etc.):
```bash
terraform apply
```
Digite yes para confirmar.

### 5️⃣ Acesse a Aplicação
A aplicação estará acessível após a execução bem-sucedida:

Aplicação Principal: [http://localhost:8080]