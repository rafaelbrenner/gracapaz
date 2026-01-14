# Bot WhatsApp para Igreja - Sistema de Automação

Sistema completo de automação para WhatsApp usando Evolution API, N8N e PostgreSQL.

## 🚀 Funcionalidades

- **Evolution API**: Conexão com WhatsApp via QR Code (com interface de gerenciamento embutida)
- **N8N**: Automação de workflows e respostas
- **PostgreSQL**: Banco de dados para armazenamento
- **Redis**: Cache para melhor performance (opcional)
- **Cloudflare Tunnel**: Acesso remoto seguro (opcional)

## 📋 Pré-requisitos

- Docker e Docker Compose instalados
- Conta Cloudflare (opcional, para acesso remoto)

## ⚙️ Configuração

### 1. Clone o repositório

```bash
git clone https://github.com/seu-usuario/graca_paz.git
cd graca_paz
```

### 2. Configure as variáveis de ambiente

```bash
# Copie o arquivo de exemplo
cp .env.example .env

# Edite o arquivo .env com suas credenciais
nano .env  # ou use seu editor preferido
```

**Importante**: Altere TODAS as senhas e tokens no arquivo `.env`:

- `POSTGRES_PASSWORD`: Senha do PostgreSQL
- `EVOLUTION_API_KEY`: Chave de API para Evolution
- `N8N_BASIC_AUTH_PASSWORD`: Senha do N8N
- `CLOUDFLARE_TUNNEL_TOKEN`: Token do Cloudflare (se usar)

### 3. Inicie os containers

```bash
docker-compose up -d
```

### 4. Acesse os serviços

- **Evolution API**: http://localhost:8080
  - **Manager (Interface de Gerenciamento)**: http://localhost:8080/manager
  - API Key: definida em `EVOLUTION_API_KEY` (.env)
  - Use o Manager para: criar instâncias, escanear QR Code, ver logs

- **N8N**: http://localhost:5678
  - Usuário: definido em `N8N_BASIC_AUTH_USER` (.env)
  - Senha: definida em `N8N_BASIC_AUTH_PASSWORD` (.env)

## 🎛️ Gerenciamento de Containers

### Interface Nativa do Evolution (Recomendado)

Acesse http://localhost:8080/manager para gerenciar o Evolution API:
- Criar e gerenciar instâncias do WhatsApp
- Escanear QR Code
- Ver status de conexões
- Configurar webhooks
- Enviar mensagens de teste

### Alternativas para Gerenciar Containers Docker

O **EasyPanel não funciona no Windows** (Docker Desktop). Alternativas:

1. **Docker Desktop GUI** (já instalado)
   - Abra o Docker Desktop
   - Vá em "Containers"
   - Gerencie visualmente todos os containers

2. **Portainer** (interface web completa)
   - Descomente a seção `portainer` no `docker-compose.yml`
   - Execute: `docker-compose up -d portainer`
   - Acesse: https://localhost:9443

3. **Outros** (Yacht, Dozzle, etc.)
   - Veja o arquivo [ALTERNATIVAS_EASYPANEL.md](ALTERNATIVAS_EASYPANEL.md)

## 🔐 Segurança

### ⚠️ IMPORTANTE - Antes de publicar no GitHub:

1. **NUNCA** commite o arquivo `.env`
2. O `.gitignore` já está configurado para proteger seus dados
3. Troque TODAS as senhas padrão em produção
4. Use senhas fortes e únicas
5. Mantenha o token do Cloudflare em segredo

### Verificando segurança antes do commit:

```bash
# Verifique se o .env não será commitado
git status

# O arquivo .env NÃO deve aparecer na lista
# Se aparecer, verifique seu .gitignore
```

## 📦 Estrutura do Projeto

```
graca_paz/
├── docker-compose.yml    # Configuração dos containers
├── .env                  # Credenciais (NÃO commitar!)
├── .env.example          # Exemplo de configuração
├── .gitignore           # Arquivos a ignorar no Git
└── README.md            # Este arquivo
```

## 🔧 Comandos Úteis

```bash
# Ver logs dos containers
docker-compose logs -f

# Ver logs de um serviço específico
docker-compose logs -f n8n
docker-compose logs -f evolution-api

# Parar todos os containers
docker-compose down

# Reiniciar um serviço específico
docker-compose restart evolution-api

# Remover tudo (incluindo volumes)
docker-compose down -v
```

## 🌐 Cloudflare Tunnel (Opcional)

Para acesso remoto seguro:

1. Crie um túnel no [Cloudflare Zero Trust](https://one.dash.cloudflare.com/)
2. Copie o token gerado
3. Adicione o token em `CLOUDFLARE_TUNNEL_TOKEN` no arquivo `.env`
4. Descomente a seção `cloudflared` no `docker-compose.yml`
5. Reinicie os containers: `docker-compose up -d`

## 🐛 Troubleshooting

### Erro de conexão com Redis

Se aparecerem erros "redis disconnected", isso é apenas um aviso. A Evolution API funciona normalmente sem o Redis, apenas com performance reduzida para cache.

### Portas já em uso

Se as portas 5678 ou 8080 já estiverem em uso, edite o `docker-compose.yml` e altere:

```yaml
ports:
  - "5679:5678"  # Altere 5679 para outra porta disponível
```

### Evolution API não conecta ao WhatsApp

1. Acesse http://localhost:8080/manager
2. Crie uma nova instância
3. Escaneie o QR Code com seu WhatsApp

## 📝 Licença

Este projeto é de código aberto. Sinta-se livre para usar e modificar.

## 🤝 Contribuindo

Contribuições são bem-vindas! Por favor:

1. Faça um fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## ⚠️ Avisos Importantes

- Este sistema é para uso educacional e em ambientes autorizados
- Respeite os Termos de Serviço do WhatsApp
- Use responsavelmente e não envie spam
- Sempre obtenha consentimento antes de enviar mensagens automatizadas
