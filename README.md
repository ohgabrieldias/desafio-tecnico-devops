# 🛠️ Desafio Técnico DevOps - Infraestrutura como Código

Este projeto implementa uma aplicação web completa (frontend, backend, banco de dados) utilizando **Docker** e **Terraform** para orquestração de containers. A infraestrutura é definida como código, permitindo deploy consistente e reproduzível.

---

## 📝 Índice

- [🏗️ Arquitetura](#️-arquitetura)
- [🌐 Redes](#-redes)
  - [1. REDE_EXTERNA (`10.10.1.0/24`)](#1-rede_externa-10101024)
  - [2. REDE_INTERNA (`10.10.0.0/24`)](#2-rede_interna-10100024)
- [🩺 Health Checks](#-health-checks)
  - [Como Funcionam no Projeto:](#como-funcionam-no-projeto)
  - [Como o Avaliador Pode Verificar:](#como-o-avaliador-pode-verificar)
- [📁 Estrutura do Projeto](#-estrutura-do-projeto)
- [🛠️ Pré-requisitos](#️-pré-requisitos)
- [🔧 Instalação de Dependências (Windows)](#-instalação-de-dependências-windows)
  - [1. Docker Desktop](#1-docker-desktop)
  - [2. Terraform](#2-terraform)
- [🐧 Para SO Linux (Ubuntu/Debian)](#-para-so-linux-ubuntudebian)
  - [1. Docker Engine](#1-docker-engine)
  - [2. Terraform](#2-terraform-1)
- [🏃 Como Executar o Projeto](#-como-executar-o-projeto)
  - [🚀 Modos de Execução e Gerenciamento de Ambiente](#-modos-de-execução-e-gerenciamento-de-ambiente)
    - [Variáveis de Ambiente para Docker Compose](#variáveis-de-ambiente-para-docker-compose)
  - [1️⃣ Clone o Repositório](#1-clone-o-repositório)
  - [1️⃣.5 Configurar Variáveis do Terraform](#15-configurar-variáveis-do-terraform)
  - [2️⃣ Inicialize o Terraform](#2-inicialize-o-terraform)
  - [3️⃣ Revise o Plano de Execução (Opcional)](#3-revise-o-plano-de-execução-opcional)
  - [4️⃣ Execute a Infraestrutura](#4-execute-a-infraestrutura)
  - [5️⃣ Acesse a Aplicação](#5-acesse-a-aplicação)
  - [6️⃣ Limpeza do Ambiente](#6-limpeza-do-ambiente)
- [🐛 Resolução de Problemas Comuns](#-resolução-de-problemas-comuns)
  - [1. Docker Daemon Não Está em Execução](#1-docker-daemon-não-está-em-execução)
  - [2. Porta Já em Uso](#2-porta-já-em-uso)
  - [3. Erros Durante `terraform apply`](#3-erros-durante-terraform-apply)
  - [4. Containers Não Iniciam ou Saem Imediatamente](#4-containers-não-iniciam-ou-saem-imediatamente)
  - [5. Aplicação Não Acessível em `http://localhost:8080`](#5-aplicação-não-acessível-em-httplocalhost8080)
- [📊 Observabilidade](#-observabilidade)
  - [1. Logs dos Containers](#1-logs-dos-containers)
  - [2. Health Checks](#2-health-checks)
- [💾 Persistência de Dados](#-persistência-de-dados)
  - [1. Volumes Docker](#1-volumes-docker)
  - [2. Inicialização do Banco de Dados](#2-inicialização-do-banco-de-dados)

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

## 🌐 Redes

O projeto utiliza duas redes Docker distintas para isolar e gerenciar o tráfego entre os serviços:

### 1. REDE_EXTERNA (`10.10.1.0/24`)
- **Propósito:** Responsável por expor o serviço de proxy Nginx ao usuário final. É a interface de comunicação entre o mundo externo e a aplicação.
- **Componentes Conectados:** Apenas o `Nginx Proxy` está diretamente conectado a esta rede, recebendo requisições na porta `8080`.

### 2. REDE_INTERNA (`10.10.0.0/24`)
- **Propósito:** Rede privada para a comunicação interna entre os serviços da aplicação (Frontend, Backend e Database). Garante que esses serviços não sejam diretamente acessíveis externamente, aumentando a segurança.
- **Componentes Conectados:**
    - `Frontend (React)`: Comunica-se com o Backend.
    - `Backend (Node.js)`: Comunica-se com o Frontend e com o Database.
    - `Database (PostgreSQL)`: Acessível apenas pelo Backend.

A comunicação entre a `REDE_EXTERNA` e a `REDE_INTERNA` é intermediada pelo `Nginx Proxy`, que atua como um gateway, roteando as requisições externas para o serviço de `Frontend` na `REDE_INTERNA`.

## 🩺 Health Checks

Os health checks são mecanismos cruciais para a orquestração e a resiliência da aplicação, especialmente quando gerenciada pelo Terraform e Docker. Eles permitem que o orquestrador determine o estado de saúde de cada serviço e tome ações corretivas, como reiniciar um container que não está respondendo.

### Como Funcionam no Projeto:

1.  **Database (PostgreSQL)**
    *   **Método:** `pg_isready -U ${DB_USER:-postgres} -d ${DB_NAME:-desafio_db}`
    *   **Verifica:** A capacidade do servidor PostgreSQL de aceitar conexões. Isso garante que o banco de dados está operacional e pronto para ser utilizado.
    *   **Configuração:** Definido no `docker-compose.yml` (e no Dockerfile, mas sobrescrito pelo compose), utilizando variáveis de ambiente para flexibilidade.
    *   **Parâmetros Chave:** `interval` (30s), `timeout` (3s), `start_period` (5s), `retries` (3).

2.  **Backend (Node.js)**
    *   **Método:** `wget --no-verbose --tries=1 --spider http://localhost:3000/health`
    *   **Verifica:** Se o endpoint `/health` da aplicação backend está respondendo, indicando que o serviço está ativo.
    *   **Configuração:** Definido no `docker-compose.yml`.
    *   **Parâmetros Chave:** `interval` (30s), `timeout` (5s), `start_period` (40s), `retries` (3).

### Como o Avaliador Pode Verificar:

Após executar `terraform apply`, você pode verificar o status dos health checks dos containers usando os comandos Docker:

-   **Verificar Status Geral:**
    ```bash
    docker ps
    ```
    Observe a coluna `STATUS`. Containers saudáveis exibirão `(healthy)`.

-   **Inspecionar Detalhes do Health Check:**
    ```bash
    docker inspect <nome_do_container> | grep Health
    ```
    (Ex: `docker inspect dsf-backend | grep Health`)
    Este comando mostrará os detalhes do último status do health check, incluindo a saída do comando de verificação.

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

### 🚀 Modos de Execução e Gerenciamento de Ambiente

É crucial entender a distinção entre as ferramentas utilizadas para diferentes ambientes:

-   **Docker Compose (Ambiente de Desenvolvimento/Testes):** O arquivo `docker-compose.yml` é fornecido para facilitar a execução local da aplicação em um ambiente de desenvolvimento ou para testes rápidos. Ele orquestra todos os serviços (frontend, backend, database, proxy) de forma simples e direta em uma única máquina Docker. **Este método é recomendado apenas para fins de desenvolvimento e teste.**

-   **Terraform (Ambiente de Produção):** Para ambientes de produção, a orquestração dos containers e a gestão da infraestrutura são realizadas através do Terraform. O Terraform define a infraestrutura como código, garantindo que o deploy seja consistente, escalável e reproduzível em ambientes de produção. Ele gerencia a criação de redes, serviços e volumes de forma declarativa e robusta. **Este é o método preferencial para deploy em produção.**

#### Variáveis de Ambiente para Docker Compose

Para o ambiente de desenvolvimento com Docker Compose, você pode definir variáveis de ambiente para personalizar a configuração do banco de dados e portas.

-   **Como Definir:** Crie um arquivo `.env` na raiz do projeto (na mesma pasta do `docker-compose.yml`) e adicione as variáveis no formato `CHAVE=VALOR`.
    ```
    DB_NAME=meu_banco_de_dados
    DB_USER=meu_usuario
    DB_PASSWORD=minha_senha_secreta
    PORT=4000
    ```
-   **Valores Padrão:** Se o arquivo `.env` não for fornecido ou se as variáveis não forem definidas, o Docker Compose utilizará os valores padrão especificados no `docker-compose.yml` (ex: `DB_NAME=desafio_db`, `DB_USER=postgres`, `DB_PASSWORD=password`, `PORT=3000`).

### 1️⃣ Clone o Repositório

Baixe o código-fonte:

```bash
git clone [https://github.com/ohgabrieldias/desafio-tecnico-devops.git](https://github.com/ohgabrieldias/desafio-tecnico-devops.git)
cd desafio-tecnico-devops
```

### 1️⃣.5 Configurar Variáveis do Terraform

Antes de inicializar o Terraform, você deve configurar as variáveis de ambiente necessárias. Um arquivo de exemplo é fornecido para sua conveniência.

1.  **Copie o arquivo de exemplo:**
    ```bash
    cp terraform/terraform.tfvars.example terraform/terraform.tfvars
    ```
2.  **Edite o arquivo `terraform/terraform.tfvars`:**
    Abra o arquivo recém-criado e ajuste os valores das variáveis conforme suas necessidades. É crucial definir uma `db_password` segura.
    ```
    db_name     = "desafio_db"
    db_user     = "postgres"
    db_password = "sua_senha_segura_aqui" # <-- ALTERE AQUI!
    backend_port = 3000
    proxy_port   = 8080
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

-   **Aplicação Principal (Frontend):** [http://localhost:8080](http://localhost:8080)
    *   Esta é a interface do usuário da aplicação.
-   **API do Backend:** [http://localhost:8080/api](http://localhost:8080/api)
    *   Este endpoint expõe a API RESTful do backend. Ao acessá-lo, você receberá um JSON com o status de saúde dos serviços internos, por exemplo: `{ "database": true, "useradmin": true }`.

---

### 6️⃣ Limpeza do Ambiente

Após concluir a avaliação ou o desenvolvimento, é importante limpar os recursos criados para evitar custos desnecessários ou conflitos.

#### Para Recursos Gerenciados pelo Terraform:

1.  **Acesse a pasta do Terraform:**
    ```bash
    cd terraform
    ```
2.  **Execute o comando `terraform destroy`:**
    ```bash
    terraform destroy
    ```
    Este comando irá destruir todos os recursos Docker (containers, redes, volumes) que foram provisionados pelo Terraform. Digite `yes` para confirmar a destruição.

#### Para Recursos Gerenciados pelo Docker Compose (se utilizado):

Se você utilizou o Docker Compose para desenvolvimento, pode limpar os recursos com o script `clean-docker.sh` fornecido:

1.  **Retorne à raiz do projeto:**
    ```bash
    cd ..
    ```
2.  **Execute o script de limpeza:**
    ```bash
    ./clean-docker.sh
    ```
    Este script irá parar e remover todos os containers, redes e volumes criados pelo Docker Compose.

---

## 🐛 Resolução de Problemas Comuns

Esta seção oferece diretrizes para diagnosticar e resolver problemas que podem surgir ao iniciar o projeto pela primeira vez.

### 1. Docker Daemon Não Está em Execução
- **Sintoma:** Erros como "Cannot connect to the Docker daemon" ou "docker: command not found".
- **Solução:**
    - **Windows/macOS:** Certifique-se de que o Docker Desktop está aberto e em execução.
    - **Linux:** Verifique o status do serviço Docker com `sudo systemctl status docker`. Se não estiver ativo, inicie-o com `sudo systemctl start docker`.

### 2. Porta Já em Uso
- **Sintoma:** Erros como "port is already allocated" ou "bind: address already in use" ao executar `terraform apply` ou `docker-compose up`.
- **Solução:** A porta `8080` é usada pelo Nginx Proxy. Verifique se outro processo na sua máquina já está usando essa porta.
    - **Linux:** `sudo netstat -tulnp | grep 8080`
    - **Windows:** `netstat -ano | findstr :8080`
    - Se encontrar um processo, você pode encerrá-lo ou alterar a porta no `proxy/nginx.conf` e no `docker-compose.yml`.

### 3. Erros Durante `terraform apply`
- **Sintoma:** O comando `terraform apply` falha com mensagens de erro relacionadas à criação de recursos Docker.
- **Solução:**
    - **Verifique o Docker:** Garanta que o Docker Daemon está em execução (veja o item 1).
    - **Logs do Terraform:** Analise a saída detalhada do Terraform para identificar qual recurso está falhando e por quê.
    - **Conflitos:** Verifique se não há containers ou redes Docker com os mesmos nomes já em execução que possam estar causando conflito. Use `docker ps -a` e `docker network ls`.

### 4. Containers Não Iniciam ou Saem Imediatamente
- **Sintoma:** Após `terraform apply`, alguns containers não ficam no estado "running" ou saem logo após iniciar.
- **Solução:**
    - **Verifique os Logs:** Use `docker logs <nome_do_container>` (ex: `docker logs dsf-backend`) para inspecionar a saída do container. Mensagens de erro no início são cruciais para entender a causa.
    - **Health Checks:** Monitore o status dos health checks (veja a seção "Health Checks"). Um container pode estar saindo porque seu health check falha repetidamente.
    - **Dependências:** Certifique-se de que os serviços dos quais o container depende estão saudáveis e em execução.

### 5. Aplicação Não Acessível em `http://localhost:8080`
- **Sintoma:** O navegador não consegue se conectar à aplicação após a execução bem-sucedida do Terraform.
- **Solução:**
    - **Nginx Proxy:** Verifique se o container `dsf-proxy` está em execução (`docker ps`) e se seus logs (`docker logs dsf-proxy`) não indicam erros de configuração.
    - **Redes:** Confirme se as redes Docker (`external_network` e `internal_network`) foram criadas corretamente (`docker network ls`).
    - **Firewall:** Verifique se o firewall da sua máquina não está bloqueando a porta `8080`.

---

## 📊 Observabilidade

A observabilidade é fundamental para entender o comportamento da aplicação em tempo real, identificar gargalos e diagnosticar problemas.

### 1. Logs dos Containers
- **Acesso:** Todos os serviços Docker geram logs padrão (stdout/stderr). Você pode acessá-los usando o comando `docker logs <nome_do_container>`.
    ```bash
    docker logs dsf-backend
    docker logs dsf-database
    docker logs dsf-frontend
    docker logs dsf-proxy
    ```
- **Importância:** Os logs são a primeira linha de defesa para depuração. Eles fornecem informações sobre o estado do serviço, erros, requisições e eventos importantes.

### 2. Health Checks
- **Monitoramento de Status:** Conforme detalhado na seção "Health Checks", cada serviço crítico possui um mecanismo para reportar seu estado de saúde.
- **Uso:** Ferramentas de orquestração como Docker Compose e Terraform utilizam esses health checks para determinar se um container está apto a receber tráfego ou se precisa ser reiniciado.
- **Verificação Manual:** Você pode verificar o status de saúde de um container manualmente com `docker inspect <nome_do_container>`.


---

## 💾 Persistência de Dados

A persistência dos dados é um aspecto crítico para garantir que as informações do banco de dados não sejam perdidas quando os containers são reiniciados ou removidos.

### 1. Volumes Docker
- **Uso:** O projeto utiliza volumes Docker para persistir os dados do PostgreSQL. No `docker-compose.yml`, o volume `postgres_data` é mapeado para `/var/lib/postgresql/data` dentro do container do banco de dados.
    ```yaml
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ```
- **Benefícios:**
    - **Durabilidade:** Os dados persistem mesmo se o container do banco de dados for destruído e recriado.
    - **Separação:** Separa os dados da camada de aplicação, facilitando backups e migrações.
- **Gerenciamento:** Os volumes Docker são gerenciados pelo Docker e podem ser inspecionados com `docker volume ls` e `docker volume inspect postgres_data`.

### 2. Inicialização do Banco de Dados
- **Script SQL:** O arquivo `sql/script.sql` é utilizado para inicializar o banco de dados com um esquema e dados iniciais. Ele é copiado para `/docker-entrypoint-initdb.d/init.sql` no container do PostgreSQL, garantindo que seja executado na primeira inicialização do banco de dados.
    ```yaml
    volumes:
      - ./sql/script.sql:/docker-entrypoint-initdb.d/init.sql
    ```
- **Importância:** Garante que o banco de dados esteja pronto para uso com a estrutura e dados mínimos necessários para a aplicação funcionar.