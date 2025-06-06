# VPS Installer Script

Script para instalação automatizada de Docker, Traefik e Portainer em VPS Ubuntu.

## Sobre

Este script automatiza a instalação e configuração dos seguintes componentes em um servidor Ubuntu 20.04 ou superior:

- Docker Engine e Docker Compose
- Traefik (como proxy reverso com suporte a HTTPS automático via Let's Encrypt)
- Portainer CE (interface gráfica para gerenciamento de contêineres Docker)
- MPC Server para Docker (permite integração com o Cursor IA)

## Requisitos

- Ubuntu 20.04 ou superior
- Privilégios de superusuário (root)
- Um domínio apontando para o IP da sua VPS
- Portas 80, 443 e 7777 liberadas no firewall

## Como Usar

1. **Conecte-se à sua VPS Ubuntu (20.04 ou superior) via SSH.**
2. **Execute o seguinte comando para baixar e rodar o script:**

   ```bash
   curl -fsSL https://raw.githubusercontent.com/LuizBranco-ClickHype/vps-installer-script/main/install.sh | sudo bash
   ```
3. **Siga as instruções do script:** Você precisará fornecer um nome de domínio (ex: `portainer.seudominio.com`) e um email para o certificado SSL (Let's Encrypt).
4. **Configure o DNS:** Certifique-se de que o domínio fornecido no passo anterior aponte para o endereço IP da sua VPS.
5. **Firewall:** Libere as portas 80 (HTTP), 443 (HTTPS) e 7777 (MPC Docker) no firewall da sua VPS.
6. **Configurar Cursor IA:** Após a execução do script e a configuração do DNS/Firewall, conecte o Cursor IA ao MPC Server do Docker. Use o endereço `http://IP_DA_SUA_VPS:7777`. Geralmente não é necessário token de acesso para este servidor específico.

Após a execução, você poderá acessar o Portainer através do domínio configurado e conectar o Cursor IA ao MPC Server no endereço http://IP-DA-VPS:7777.

## Método Alternativo de Instalação

1. Faça login na sua VPS via SSH

2. Baixe o script de instalação:
```bash
wget https://raw.githubusercontent.com/LuizBranco-ClickHype/vps-installer-script/main/install.sh
```

3. Torne o script executável:
```bash
chmod +x install.sh
```

4. Execute o script:
```bash
sudo ./install.sh
```

5. Siga as instruções para fornecer seu domínio e endereço de e-mail para o Let's Encrypt

## Após a instalação

Depois que a instalação for concluída com sucesso, você poderá acessar:

- Portainer: https://portainer.seu-dominio.com
- Traefik Dashboard: https://traefik.seu-dominio.com (usuário: admin, senha: admin)
- MPC Server (para Cursor IA): http://IP-DA-VPS:7777

## Importante

Certifique-se de configurar os registros DNS corretos para os subdomínios:
- portainer.seu-dominio.com
- traefik.seu-dominio.com

Para usar o Cursor IA com o MPC Server, configure a conexão nas configurações do Cursor apontando para http://IP-DA-VPS:7777.

## Licença

Este projeto está licenciado sob a licença MIT - veja o arquivo LICENSE para mais detalhes.