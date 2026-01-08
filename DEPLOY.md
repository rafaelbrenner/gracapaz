# Guia de Deploy

Este guia fornece instruções passo a passo para fazer o deploy seguro do sistema.

## 📋 Pré-Deploy Checklist

Antes de iniciar o deploy, certifique-se de:

- [ ] Ler completamente o [README.md](README.md)
- [ ] Revisar as práticas de segurança em [SECURITY.md](SECURITY.md)
- [ ] Ter acesso a um servidor ou VPS
- [ ] Ter Docker e Docker Compose instalados no servidor
- [ ] Ter as credenciais preparadas

## 🚀 Deploy em Servidor/VPS

### 1. Preparar o Servidor

```bash
# Atualize o sistema
sudo apt update && sudo apt upgrade -y

# Instale Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Instale Docker Compose
sudo apt install docker-compose -y

# Adicione seu usuário ao grupo docker
sudo usermod -aG docker $USER
newgrp docker
```

### 2. Clone o Repositório

```bash
# Via HTTPS
git clone https://github.com/seu-usuario/graca_paz.git
cd graca_paz

# Ou via SSH (recomendado)
git clone git@github.com:seu-usuario/graca_paz.git
cd graca_paz
```

### 3. Configure as Variáveis de Ambiente

```bash
# Copie o arquivo de exemplo
cp .env.example .env

# Edite com um editor seguro
nano .env
```

**IMPORTANTE**: Gere senhas fortes para TODAS as variáveis:

```bash
# Exemplo de geração de senhas fortes
openssl rand -base64 32  # Para POSTGRES_PASSWORD
openssl rand -base64 32  # Para EVOLUTION_API_KEY
openssl rand -base64 32  # Para N8N_BASIC_AUTH_PASSWORD
```

### 4. Configure o Firewall

```bash
# UFW (Ubuntu/Debian)
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw enable

# Opcional: Se quiser acesso direto às portas
# sudo ufw allow 5678/tcp  # N8N
# sudo ufw allow 8080/tcp  # Evolution API
```

### 5. Inicie os Containers

```bash
# Inicie em modo detached
docker-compose up -d

# Verifique os logs
docker-compose logs -f
```

### 6. Configure SSL/TLS (Produção)

#### Opção 1: Cloudflare Tunnel (Recomendado)

1. Acesse [Cloudflare Zero Trust](https://one.dash.cloudflare.com/)
2. Crie um novo túnel
3. Configure os hostnames:
   - `n8n.seudominio.com` → `http://n8n:5678`
   - `evolution.seudominio.com` → `http://evolution-api:8080`
4. Copie o token do túnel
5. Adicione ao `.env`:
   ```bash
   CLOUDFLARE_TUNNEL_TOKEN=seu_token_aqui
   ```
6. Descomente a seção cloudflared no `docker-compose.yml`
7. Reinicie: `docker-compose up -d`

#### Opção 2: Nginx + Let's Encrypt

```bash
# Instale Nginx e Certbot
sudo apt install nginx certbot python3-certbot-nginx -y

# Configure o Nginx (ver exemplo abaixo)
sudo nano /etc/nginx/sites-available/graca_paz

# Obtenha certificados SSL
sudo certbot --nginx -d n8n.seudominio.com -d evolution.seudominio.com

# Configure renovação automática
sudo certbot renew --dry-run
```

**Exemplo de configuração Nginx:**

```nginx
# N8N
server {
    server_name n8n.seudominio.com;

    location / {
        proxy_pass http://localhost:5678;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}

# Evolution API
server {
    server_name evolution.seudominio.com;

    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

## 🔄 Atualizações

### Atualizar o Sistema

```bash
# Puxe as últimas mudanças
git pull origin main

# Atualize as imagens Docker
docker-compose pull

# Reinicie os containers
docker-compose down
docker-compose up -d
```

### Rollback

```bash
# Se algo der errado, volte para a versão anterior
git log --oneline  # Veja os commits
git checkout <commit-hash>
docker-compose down
docker-compose up -d
```

## 💾 Backup

### Backup Manual

```bash
# Script de backup
#!/bin/bash
BACKUP_DIR="/backup/graca_paz"
DATE=$(date +%Y%m%d_%H%M%S)

# Criar diretório de backup
mkdir -p $BACKUP_DIR

# Backup do PostgreSQL
docker exec postgres pg_dump -U root evolution > $BACKUP_DIR/postgres_$DATE.sql

# Backup dos volumes Docker
docker run --rm -v graca_paz_postgres_data:/data -v $BACKUP_DIR:/backup \
  alpine tar czf /backup/postgres_volume_$DATE.tar.gz -C /data .

docker run --rm -v graca_paz_n8n_data:/data -v $BACKUP_DIR:/backup \
  alpine tar czf /backup/n8n_volume_$DATE.tar.gz -C /data .

docker run --rm -v graca_paz_evolution_instances:/data -v $BACKUP_DIR:/backup \
  alpine tar czf /backup/evolution_volume_$DATE.tar.gz -C /data .

# Backup do arquivo .env (criptografado)
gpg -c -o $BACKUP_DIR/env_$DATE.gpg .env

echo "Backup concluído: $BACKUP_DIR"
```

### Backup Automatizado com Cron

```bash
# Edite o crontab
crontab -e

# Adicione (backup diário às 3h da manhã)
0 3 * * * /caminho/para/backup.sh

# Backup semanal (domingos às 4h)
0 4 * * 0 /caminho/para/backup_completo.sh
```

### Restauração

```bash
# Restaurar PostgreSQL
cat backup_postgres_20260108.sql | docker exec -i postgres psql -U root evolution

# Restaurar volumes
docker run --rm -v graca_paz_postgres_data:/data -v /backup:/backup \
  alpine tar xzf /backup/postgres_volume_20260108.tar.gz -C /data
```

## 📊 Monitoramento

### Logs

```bash
# Todos os logs
docker-compose logs -f

# Logs de um serviço específico
docker-compose logs -f evolution-api

# Últimas 100 linhas
docker-compose logs --tail=100

# Desde determinado horário
docker-compose logs --since 30m
```

### Métricas

```bash
# Uso de recursos
docker stats

# Disco
df -h
docker system df
```

### Alertas (Opcional)

Configure alertas usando ferramentas como:
- **Uptime Robot**: Monitora disponibilidade
- **Grafana + Prometheus**: Métricas detalhadas
- **Portainer**: Interface web para Docker

## 🔧 Troubleshooting

### Container não inicia

```bash
# Veja os logs
docker-compose logs [nome-do-container]

# Recrie o container
docker-compose up -d --force-recreate [nome-do-container]
```

### Erro de permissão

```bash
# Ajuste permissões dos volumes
sudo chown -R 1000:1000 ./volumes
```

### Falta de espaço em disco

```bash
# Limpe imagens não utilizadas
docker system prune -a

# Limpe volumes não utilizados
docker volume prune
```

### Performance ruim

```bash
# Aumente recursos do container
# Edite docker-compose.yml e adicione:
services:
  evolution-api:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
```

## 🛡️ Hardening de Segurança

### 1. SSH

```bash
# Desabilite login root
sudo nano /etc/ssh/sshd_config
# PermitRootLogin no

# Use apenas chaves SSH
# PasswordAuthentication no

sudo systemctl restart sshd
```

### 2. Fail2Ban

```bash
# Instale Fail2Ban
sudo apt install fail2ban -y

# Configure
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo nano /etc/fail2ban/jail.local

sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

### 3. Atualizações Automáticas

```bash
# Instale unattended-upgrades
sudo apt install unattended-upgrades -y
sudo dpkg-reconfigure -plow unattended-upgrades
```

## 📞 Suporte

Se encontrar problemas:

1. Verifique os logs: `docker-compose logs -f`
2. Consulte o [README.md](README.md) e [SECURITY.md](SECURITY.md)
3. Procure issues no GitHub
4. Abra uma nova issue com detalhes do problema

---

**Última atualização**: 2026-01-08
