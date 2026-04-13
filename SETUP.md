# Guia de Configuração — Projeto Graça e Paz

Documentação completa para instalar e configurar o ambiente de automação WhatsApp com Evolution API, N8N e PostgreSQL.

---

## Índice

1. [Pré-requisitos](#pré-requisitos)
2. [Estrutura do Projeto](#estrutura-do-projeto)
3. [Configuração do .env](#configuração-do-env)
4. [Subindo os Containers](#subindo-os-containers)
5. [Evolution API — Configuração e Instância WhatsApp](#evolution-api)
6. [N8N — Automação](#n8n)
7. [pgAdmin — Banco de Dados](#pgadmin)
8. [Portainer — Gerenciamento de Containers](#portainer)
9. [Troubleshooting](#troubleshooting)

---

## Pré-requisitos

- **Docker** 24+ instalado
- **Docker Compose** v2+ (já incluso no Docker Desktop)
- Porta 8080, 5678, 5050, 9000 livres
- Acesso à internet (o Baileys/WhatsApp precisa conectar nos servidores do WhatsApp)

---

## Estrutura do Projeto

```
gracapaz/
├── docker-compose.yml      # Definição de todos os serviços
├── .env                    # Variáveis de ambiente (NÃO commitar no Git)
├── .env.example            # Modelo do .env
├── workflows/              # Workflows do N8N exportados
└── SETUP.md                # Este arquivo
```

---

## Configuração do .env

Copie o `.env.example` para `.env` e preencha as variáveis:

```bash
cp .env.example .env
```

Conteúdo do `.env`:

```env
# PostgreSQL
POSTGRES_USER=root
POSTGRES_PASSWORD=senha_forte_aqui
POSTGRES_DB=evolution
N8N_DB=n8n

# Evolution API
EVOLUTION_API_KEY=chave_api_forte_aqui
SERVER_URL=http://localhost:8080

# N8N
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=senha_forte_aqui
N8N_WEBHOOK_URL=http://localhost:5678

# pgAdmin
PGADMIN_EMAIL=admin@admin.com
PGADMIN_PASSWORD=senha_forte_aqui

# Cloudflare Tunnel (opcional)
CLOUDFLARE_TUNNEL_TOKEN=seu_token_aqui
```

> **Nunca commite o arquivo `.env` no Git.** Ele já está no `.gitignore`.

Para gerar senhas seguras:
```bash
openssl rand -hex 32
```

---

## Subindo os Containers

```bash
# Primeira vez ou após mudanças no docker-compose.yml
docker compose up -d

# Ver status dos containers
docker ps

# Ver logs de um serviço específico
docker logs evolution-api -f
```

Serviços e portas:

| Serviço       | URL                        | Descrição                   |
|---------------|----------------------------|-----------------------------|
| Evolution API | http://localhost:8080      | API WhatsApp                |
| N8N           | http://localhost:5678      | Automação de workflows      |
| pgAdmin       | http://localhost:5050      | Interface do PostgreSQL     |
| Portainer     | http://localhost:9000      | Gerenciamento de containers |

---

## Evolution API

### Dados da instância

| Campo | Valor |
|---|---|
| **Nome da instância** | `gracapaz` |
| **Número WhatsApp** | (ver arquivo `.env`) |
| **Token da instância** | `SUA_INSTANCE_TOKEN_AQUI` |
| **Channel** | Baileys |

### Versões utilizadas

| Componente                    | Versão / Valor          |
|-------------------------------|-------------------------|
| Imagem Docker                 | `atendai/evolution-api:latest` (v2.2.3) |
| Baileys (lib WhatsApp)        | `6.7.12`                |
| `CONFIG_SESSION_PHONE_VERSION`| `2.3000.1033846690`     |

> **IMPORTANTE:** A variável `CONFIG_SESSION_PHONE_VERSION` é crítica. Sem ela ou com valor desatualizado, o Baileys fica em loop de reconexão e **o QR Code não é gerado**. Sempre verifique a versão correta consultando:
> ```bash
> docker exec evolution-api node -e "
> const { fetchLatestBaileysVersion } = require('/evolution/node_modules/baileys');
> fetchLatestBaileysVersion().then(v => console.log(JSON.stringify(v)));
> "
> ```

### Variáveis de ambiente da Evolution API (docker-compose.yml)

```yaml
environment:
  # URL pública do servidor (mude para IP/domínio em produção)
  - SERVER_URL=http://localhost:8080
  - AUTHENTICATION_API_KEY=${EVOLUTION_API_KEY}

  # Banco de dados
  - DATABASE_ENABLED=true
  - DATABASE_PROVIDER=postgresql
  - DATABASE_CONNECTION_URI=postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB}?schema=public
  - DATABASE_SAVE_DATA_INSTANCE=true
  - DATABASE_SAVE_DATA_NEW_MESSAGE=true
  - DATABASE_SAVE_MESSAGE_UPDATE=true

  # Redis (cache)
  - REDIS_ENABLED=true
  - REDIS_URI=redis://redis:6379
  - REDIS_PREFIX_KEY=evolution

  # Webhook global para o N8N
  - WEBHOOK_GLOBAL_URL=http://localhost:5678/webhook
  - WEBHOOK_GLOBAL_ENABLED=true
  - WEBHOOK_GLOBAL_WEBHOOK_BY_EVENTS=true

  # QR Code
  - QRCODE_LIMIT=30
  - QRCODE_COLOR=#000000

  # Versão do WhatsApp — CRÍTICO, manter atualizado
  - CONFIG_SESSION_PHONE_CLIENT=Evolution API
  - CONFIG_SESSION_PHONE_NAME=Chrome
  - CONFIG_SESSION_PHONE_VERSION=2.3000.1033846690
```

### Criando uma instância WhatsApp

#### Opção 1 — Via interface web

1. Acesse http://localhost:8080/manager
2. Clique em **New Instance**
3. Preencha:
   - **Name**: `gracapaz` (ou o nome desejado)
   - **Channel**: `Baileys`
   - **Token**: deixe em branco (gerado automaticamente)
   - **Number**: deixe em branco (para usar QR Code)
4. Clique em **Create**

> **Atenção:** Não preencha o campo **Number** ao criar a instância. Quando um número é informado, o Evolution usa código de pareamento em vez de QR Code.

#### Opção 2 — Via API (curl)

```bash
curl -X POST "http://localhost:8080/instance/create" \
  -H "apikey: SUA_EVOLUTION_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"instanceName": "gracapaz", "integration": "WHATSAPP-BAILEYS"}'
```

### Conectando o WhatsApp (QR Code)

#### Via interface web
1. Acesse http://localhost:8080/manager
2. Clique na instância `gracapaz`
3. Clique em **Connect** — o QR Code será exibido
4. No celular: **WhatsApp → Dispositivos Conectados → Conectar um dispositivo**
5. Escaneie o QR Code

#### Via API
```bash
# Gerar QR Code
curl -X GET "http://localhost:8080/instance/connect/gracapaz" \
  -H "apikey: SUA_EVOLUTION_API_KEY"

# Salvar QR Code como imagem
curl -s "http://localhost:8080/instance/connect/gracapaz" \
  -H "apikey: SUA_EVOLUTION_API_KEY" | python3 -c "
import sys, json, base64
data = json.load(sys.stdin)
with open('qrcode.png', 'wb') as f:
    f.write(base64.b64decode(data['base64'].split(',')[1]))
print('QR Code salvo em qrcode.png')
"
```

### Verificar status da instância

```bash
curl -X GET "http://localhost:8080/instance/fetchInstances" \
  -H "apikey: SUA_EVOLUTION_API_KEY"
```

Resposta esperada quando conectado:
```json
[{
  "name": "gracapaz",
  "connectionStatus": "open",
  "integration": "WHATSAPP-BAILEYS"
}]
```

### Atualizar CONFIG_SESSION_PHONE_VERSION

A versão do WhatsApp muda periodicamente. Quando o QR Code parar de ser gerado, execute:

```bash
# 1. Verificar versão atual
docker exec evolution-api node -e "
const { fetchLatestBaileysVersion } = require('/evolution/node_modules/baileys');
fetchLatestBaileysVersion().then(v => console.log('Nova versão:', JSON.stringify(v)));
"

# 2. Atualizar no docker-compose.yml
# CONFIG_SESSION_PHONE_VERSION=2.3000.XXXXXXXXXX

# 3. Recriar o container
docker compose up -d --force-recreate evolution-api
```

---

## N8N

### Acesso

- URL: http://localhost:5678
- Usuário: valor de `N8N_BASIC_AUTH_USER` (padrão: `admin`)
- Senha: valor de `N8N_BASIC_AUTH_PASSWORD`

### Importar workflows

1. Acesse o N8N
2. Vá em **Workflows → Import from file**
3. Selecione os arquivos da pasta `workflows/`

### Configurar credencial da Evolution API no N8N

1. Vá em **Credentials → New**
2. Tipo: **HTTP Header Auth**
3. Nome: `Evolution API`
4. Header: `apikey`
5. Value: o valor de `EVOLUTION_API_KEY`

---

## pgAdmin

### Acesso

- URL: http://localhost:5050
- Email: valor de `PGADMIN_EMAIL` (padrão: `admin@admin.com`)
- Senha: valor de `PGADMIN_PASSWORD`

### Conectar ao banco

1. Acesse o pgAdmin
2. **Add New Server**
3. Preencha:
   - **Name**: `gracapaz`
   - **Host**: `postgres`
   - **Port**: `5432`
   - **Database**: `evolution`
   - **Username**: valor de `POSTGRES_USER`
   - **Password**: valor de `POSTGRES_PASSWORD`

---

## Portainer

### Acesso

- URL: http://localhost:9000
- Configure usuário e senha no primeiro acesso

O Portainer permite gerenciar todos os containers via interface web — iniciar, parar, ver logs, inspecionar volumes, etc.

---

## Troubleshooting

### QR Code não é gerado / Evolution API em loop de conexão

**Sintoma:** Logs mostram `state: 'connecting'` repetidamente sem gerar QR Code.

**Causa:** `CONFIG_SESSION_PHONE_VERSION` desatualizado.

**Solução:**
```bash
# 1. Buscar versão atual
docker exec evolution-api node -e "
const { fetchLatestBaileysVersion } = require('/evolution/node_modules/baileys');
fetchLatestBaileysVersion().then(v => console.log(JSON.stringify(v)));
"

# 2. Atualizar CONFIG_SESSION_PHONE_VERSION no docker-compose.yml
# Formato: 2.3000.XXXXXXXXXX

# 3. Recriar container
docker compose up -d --force-recreate evolution-api
```

### Erros "redis disconnected" nos logs

**Causa:** Normal — o Evolution API tem um loop de reconexão com o Redis. Não impede o funcionamento desde que o Redis esteja saudável.

**Verificar:**
```bash
docker exec redis redis-cli ping
# Resposta esperada: PONG
```

### Container não sobe / porta em uso

```bash
# Ver qual processo usa a porta
sudo lsof -i :8080

# Reiniciar todos os containers
docker compose restart
```

### Recriar tudo do zero

```bash
# Para e remove containers e volumes (apaga dados!)
docker compose down -v

# Sobe novamente
docker compose up -d
```

### Verificar versão do Baileys instalado

```bash
docker exec evolution-api node -e "
const p = require('/evolution/node_modules/baileys/package.json');
console.log('Baileys:', p.version);
"
```