#!/bin/bash

# Script de instalação automatizada de Docker, Traefik e Portainer
# Para Ubuntu 20.04 ou superior

# Cores para formatação
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Função para exibir mensagens de erro e sair
function erro() {
    echo -e "${RED}[ERRO] $1${NC}"
    exit 1
}

# Função para exibir mensagens de informação
function info() {
    echo -e "${YELLOW}[INFO] $1${NC}"
}

# Função para exibir mensagens de sucesso
function sucesso() {
    echo -e "${GREEN}[SUCESSO] $1${NC}"
}

# Verificar se está sendo executado como root
if [ "$EUID" -ne 0 ]; then
  erro "Este script precisa ser executado como root (sudo)"
fi

# Coleta de informações do usuário
echo "==== Configuração do Traefik e Portainer ===="
read -p "Digite o domínio que será usado (ex: example.com): " DOMINIO
read -p "Digite o seu email (para Let's Encrypt): " EMAIL

if [ -z "$DOMINIO" ] || [ -z "$EMAIL" ]; then
    erro "Domínio e email são obrigatórios"
fi

# 1. Atualizar pacotes do sistema
info "Atualizando pacotes do sistema..."
apt update -y || erro "Falha ao atualizar pacotes"
sucesso "Pacotes atualizados"

# 2. Instalar dependências
info "Instalando dependências necessárias..."
apt install -y apt-transport-https ca-certificates curl gnupg lsb-release || erro "Falha ao instalar dependências"
sucesso "Dependências instaladas"

# 3. Adicionar chave GPG oficial do Docker
info "Adicionando chave GPG do Docker..."
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg || erro "Falha ao adicionar chave GPG do Docker"
sucesso "Chave GPG do Docker adicionada"

# 4. Configurar repositório estável do Docker
info "Configurando repositório do Docker..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null || erro "Falha ao configurar repositório do Docker"
apt update -y || erro "Falha ao atualizar pacotes após adicionar repositório Docker"
sucesso "Repositório do Docker configurado"

# 5. Instalar Docker Engine, CLI, Containerd e Docker Compose Plugin
info "Instalando Docker e componentes relacionados..."
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin || erro "Falha ao instalar Docker"
sucesso "Docker instalado com sucesso"

# 6. Criar rede traefik_proxy do Docker
info "Criando rede traefik_proxy..."
docker network create traefik_proxy || erro "Falha ao criar rede traefik_proxy"
sucesso "Rede traefik_proxy criada"

# 7. Criar diretório e configuração do docker-compose
info "Configurando Traefik e Portainer..."
mkdir -p /opt/stack || erro "Falha ao criar diretório /opt/stack"
mkdir -p /opt/stack/traefik/data || erro "Falha ao criar diretório para o Traefik"
touch /opt/stack/traefik/data/acme.json || erro "Falha ao criar arquivo acme.json"
chmod 600 /opt/stack/traefik/data/acme.json || erro "Falha ao definir permissões para acme.json"

# Criar configuração do docker-compose
cat > /opt/stack/docker-compose.yml << EOF
version: '3'

services:
  traefik:
    image: traefik:latest
    container_name: traefik
    restart: always
    networks:
      - traefik_proxy
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./traefik/data/acme.json:/acme.json
    command:
      - "--api.insecure=false"
      - "--api.dashboard=true"
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
      - "--certificatesresolvers.myresolver.acme.tlschallenge=true"
      - "--certificatesresolvers.myresolver.acme.email=${EMAIL}"
      - "--certificatesresolvers.myresolver.acme.storage=/acme.json"
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.traefik-dashboard.rule=Host(\`traefik.${DOMINIO}\`)"
      - "traefik.http.routers.traefik-dashboard.service=api@internal"
      - "traefik.http.routers.traefik-dashboard.entrypoints=websecure"
      - "traefik.http.routers.traefik-dashboard.tls.certresolver=myresolver"
      - "traefik.http.routers.traefik-dashboard.middlewares=traefik-auth"
      - "traefik.http.middlewares.traefik-auth.basicauth.users=admin:$$apr1$$v8ymzeuk$$DTjd5YZmiPpd18cb9LPGv1" # usuário: admin, senha: admin

  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    restart: always
    networks:
      - traefik_proxy
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - portainer_data:/data
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.portainer.rule=Host(\`portainer.${DOMINIO}\`)"
      - "traefik.http.routers.portainer.entrypoints=websecure"
      - "traefik.http.routers.portainer.tls.certresolver=myresolver"
      - "traefik.http.services.portainer.loadbalancer.server.port=9000"

networks:
  traefik_proxy:
    external: true

volumes:
  portainer_data:
EOF

sucesso "Arquivo docker-compose.yml criado em /opt/stack"

# 8. Iniciar os serviços
info "Iniciando Traefik e Portainer..."
cd /opt/stack
docker compose up -d || erro "Falha ao iniciar os contêineres"
sucesso "Serviços iniciados com sucesso!"

# Iniciar MPC Server para Docker
info "Iniciando o MPC Server para Docker..."
docker run -d \
  --name mcp-docker-server \
  --restart always \
  -p 7777:8000 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  ghcr.io/quantgeekdev/docker-mcp:latest || erro "Falha ao iniciar o MPC Server"
sucesso "MPC Server iniciado com sucesso na porta 7777!"

# Obter o IP público da máquina
IP=$(curl -s http://ifconfig.me)

# 9. Mensagem final
echo ""
echo "======================================================================"
echo "INSTALAÇÃO CONCLUÍDA COM SUCESSO!"
echo "======================================================================"
echo ""
echo "Serviços instalados e configurados:"
echo " - Docker, Traefik e Portainer estão rodando."
echo " - O MPC Server para Docker está rodando na porta 7777."
echo ""
echo "Próximos Passos:"
echo " 1. Configure o DNS dos subdomínios para apontar para o IP desta VPS ($IP):"
echo "    - portainer.${DOMINIO}"
echo "    - traefik.${DOMINIO}"
echo " 2. Libere as portas 80, 443 e 7777 no firewall da VPS."
echo " 3. Acesse o Portainer em https://portainer.${DOMINIO}"
echo " 4. Configure o Cursor IA para conectar ao MPC Server em http://$IP:7777"
echo ""
echo "Credenciais iniciais para o Traefik Dashboard:"
echo "  - Usuário: admin"
echo "  - Senha: admin"
echo ""
echo "Você precisará configurar uma senha para o Portainer no primeiro acesso."
echo "======================================================================"