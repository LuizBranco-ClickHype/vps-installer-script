# VPS Installer Script

Script para instalação automatizada de Docker, Traefik e Portainer em VPS Ubuntu.

## Sobre

Este script automatiza a instalação e configuração dos seguintes componentes em um servidor Ubuntu 20.04 ou superior:

- Docker Engine e Docker Compose
- Traefik (como proxy reverso com suporte a HTTPS automático via Let's Encrypt)
- Portainer CE (interface gráfica para gerenciamento de contêineres Docker)

## Requisitos

- Ubuntu 20.04 ou superior
- Privilégios de superusuário (root)
- Um domínio apontando para o IP da sua VPS
- Portas 80 e 443 liberadas no firewall

## Como usar

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

## Importante

Certifique-se de configurar os registros DNS corretos para os subdomínios:
- portainer.seu-dominio.com
- traefik.seu-dominio.com

## Licença

Este projeto está licenciado sob a licença MIT - veja o arquivo LICENSE para mais detalhes.