# Solução de Problemas e Configuração do Terraform para DigitalOcean Kubernetes (DOKS)

Este documento detalha os problemas encontrados durante o provisionamento de recursos Kubernetes na DigitalOcean usando Terraform e as soluções aplicadas.

## Problema 1: Erro "User "system:anonymous" cannot create resource"

**Descrição:**
Ao tentar aplicar os recursos Kubernetes (`namespaces`, `secrets`, `persistentvolumeclaims`, `services`, `deployments`), o Terraform retornava erros indicando que o usuário "system:anonymous" não tinha permissão para criar esses recursos. Isso ocorria mesmo após o cluster DOKS ter sido criado com sucesso.

**Causa:**
O provedor Kubernetes do Terraform, embora configurado para usar as credenciais do cluster DOKS recém-criado (`digitalocean_kubernetes_cluster.desafio_doks.kube_config`), não estava conseguindo se autenticar corretamente no cluster. O erro "system:anonymous" é um indicativo de falha na autenticação, onde o cluster não reconhece as credenciais fornecidas. Isso pode ocorrer devido a:
1. O cluster DOKS ainda não estava totalmente pronto para aceitar conexões autenticadas no momento da aplicação dos recursos Kubernetes.
2. As credenciais decodificadas do `kube_config` não estavam sendo interpretadas corretamente pelo provedor Kubernetes do Terraform.

**Solução Aplicada:**

1.  **Uso de `data` resource para o cluster DOKS:**
    Foi adicionado um `data "digitalocean_kubernetes_cluster"` em [`terraform/main.tf`](terraform/main.tf) para referenciar o cluster DOKS existente. O provedor Kubernetes foi então configurado para usar as credenciais (`host`, `client_certificate`, `client_key`, `cluster_ca_certificate`) desse `data` resource.
    *   **Por que foi necessário:** O `data` resource garante que o Terraform espere até que o cluster DOKS esteja completamente provisionado e suas informações (incluindo o `kube_config`) estejam estáveis e prontas para serem usadas. Embora o `resource` já implicasse uma dependência, o `data` resource adiciona uma camada extra de garantia de que o cluster está "pronto para uso" antes que o provedor Kubernetes tente se conectar.

2.  **Configuração do provedor Kubernetes com `config_path`:**
    Após verificar que o `kubectl` funcionava corretamente com o kubeconfig baixado localmente (`~/.kube/config`), o provedor Kubernetes em [`terraform/main.tf`](terraform/main.tf) foi modificado para usar o parâmetro `config_path = "~/.kube/config"`.
    *   **Por que foi necessário:** Isso força o provedor Kubernetes do Terraform a usar o mesmo arquivo de configuração que o `kubectl` utiliza com sucesso. Isso elimina qualquer ambiguidade ou problema de interpretação das credenciais diretamente fornecidas pelo `digitalocean_kubernetes_cluster.kube_config`, garantindo que o Terraform se autentique da mesma forma que o `kubectl`.

## Problema 2: Erro "not enough available droplet limit"

**Descrição:**
Ao tentar criar o cluster DOKS, o Terraform retornava um erro de validação indicando que não havia limite de droplets suficiente para provisionar os nós do cluster.

**Causa:**
A conta da DigitalOcean tinha um limite de droplets que impedia a criação de 2 nós adicionais, conforme configurado na variável `node_count`.

**Solução Aplicada:**

1.  **Redução do `node_count`:**
    O valor padrão da variável `node_count` em [`terraform/variables.tf`](terraform/variables.tf) foi alterado de `2` para `1`.
    *   **Por que foi necessário:** Para contornar a restrição de limite de droplets da conta DigitalOcean, o número de nós no pool de nós do cluster Kubernetes foi reduzido para o mínimo necessário (1 nó). Isso permitiu que o cluster fosse provisionado sem exceder o limite da conta.

## Passos para Depuração e Verificação (kubectl)

Durante o processo de depuração, foi crucial verificar a autenticação do `kubectl` localmente:

1.  **Baixar Kubeconfig:**
    `doctl kubernetes cluster kubeconfig save desafio-devops-cluster`
    (Se houver problemas de permissão com Snap, execute `sudo snap connect doctl:kube-config` primeiro).

2.  **Configurar `KUBECONFIG` (se necessário):**
    `export KUBECONFIG=~/.kube/config`

3.  **Verificar Nós:**
    `kubectl get nodes`

Esses passos confirmaram que o problema de autenticação não era com as credenciais do cluster em si, mas com a forma como o Terraform estava tentando utilizá-las.