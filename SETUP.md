# Guia de Configuração — Projeto Graça e Paz

Documentação completa para instalar e configurar o ambiente de automação WhatsApp com o **WhatsApp Cloud API (Meta — canal oficial)**, N8N e PostgreSQL.

> O setup do canal oficial da Meta (do zero) está em **[META_SETUP.md](META_SETUP.md)**.

---

## Índice

1. [Pré-requisitos](#pré-requisitos)
2. [Estrutura do Projeto](#estrutura-do-projeto)
3. [Configuração do .env](#configuração-do-env)
4. [Subindo os Containers](#subindo-os-containers)
5. [WhatsApp Cloud API (Meta)](#whatsapp-cloud-api-meta)
6. [N8N — Automação](#n8n)
7. [pgAdmin — Banco de Dados](#pgadmin)
8. [Portainer — Gerenciamento de Containers](#portainer)
9. [Troubleshooting](#troubleshooting)

---

## Pré-requisitos

- **Docker** 24+ instalado
- **Docker Compose** v2+ (já incluso no Docker Desktop)
- Porta 5678, 5050, 80/443 livres
- Domínio com HTTPS público para o webhook da Meta (ex: `n8n.gracaepazdf.org.br`)
- Conta Meta Business + número dedicado (ver [META_SETUP.md](META_SETUP.md))

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

# WhatsApp Cloud API (Meta) — ver META_SETUP.md
GRAPH_API_VERSION=v21.0
WHATSAPP_PHONE_NUMBER_ID=seu_phone_number_id
WHATSAPP_WABA_ID=seu_waba_id
WHATSAPP_TOKEN=seu_token_permanente
WHATSAPP_VERIFY_TOKEN=string_aleatoria_secreta

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
docker logs n8n -f
```

Serviços e portas:

| Serviço       | URL                        | Descrição                   |
|---------------|----------------------------|-----------------------------|
| N8N           | http://localhost:5678      | Automação de workflows      |
| pgAdmin       | http://localhost:5050      | Interface do PostgreSQL     |
| Nginx (form)  | http://localhost:3001      | Formulário de escala        |

---

## WhatsApp Cloud API (Meta)

A conexão com o WhatsApp é feita pelo **canal oficial da Meta** — não há container nem QR Code.
Todo o passo a passo (criar app, registrar o número **(61) 3028-0665**, gerar o token
permanente e cadastrar o webhook) está em **[META_SETUP.md](META_SETUP.md)**.

### Como funciona

```
Recebe:  Meta ──POST──► https://n8n.gracaepazdf.org.br/webhook/whatsapp
Verifica: Meta ──GET──► mesma URL (workflow responde hub.challenge)
Envia:   N8N ──POST──► https://graph.facebook.com/<versão>/<PHONE_NUMBER_ID>/messages
```

### Valores no `.env`

| Variável                   | Origem                          |
|----------------------------|---------------------------------|
| `GRAPH_API_VERSION`        | versão da Graph API (ex: v21.0) |
| `WHATSAPP_PHONE_NUMBER_ID` | WhatsApp → API Setup            |
| `WHATSAPP_WABA_ID`         | WhatsApp → API Setup            |
| `WHATSAPP_TOKEN`           | token permanente do System User |
| `WHATSAPP_VERIFY_TOKEN`    | string aleatória secreta        |

`GRAPH_API_VERSION` e `WHATSAPP_PHONE_NUMBER_ID` são passados ao container do N8N e usados via
`$env` nas URLs dos nós de envio. O `WHATSAPP_TOKEN` fica na credencial Header Auth
`WhatsApp Cloud API` (`Authorization: Bearer <token>`).

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

### Configurar credencial do WhatsApp Cloud API no N8N

1. Vá em **Credentials → New**
2. Tipo: **HTTP Header Auth**
3. Nome: `WhatsApp Cloud API`
4. Header (Name): `Authorization`
5. Value: `Bearer <WHATSAPP_TOKEN>`

> Após importar o workflow, reabra cada nó de envio e selecione essa credencial — nós
> importados não a herdam automaticamente.

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

### Webhook da Meta não verifica ("Verify and Save" falha)

**Causa:** workflow inativo, `WHATSAPP_VERIFY_TOKEN` diferente do cadastrado na Meta, ou uso da
URL de teste (`/webhook-test/`).

**Solução:** ativar o workflow `bot-menu-principal`, conferir o token e usar a URL de produção
`https://n8n.gracaepazdf.org.br/webhook/whatsapp`. Verificar nos logs do N8N a execução do
webhook GET respondendo o `hub.challenge`.

### Erro 401/403 ao enviar mensagem

**Causa:** `WHATSAPP_TOKEN` inválido/expirado ou credencial sem `Bearer`.

**Solução:** usar o token **permanente** do System User (não o temporário de 24h) e conferir
`Authorization: Bearer <token>` na credencial `WhatsApp Cloud API`.

### Bot não responde a uma mensagem recebida

**Verificar:**
```bash
docker logs n8n -f
```
Conferir se a execução do webhook POST aparece. Se a Meta não está chamando o webhook, revisar
a assinatura do campo `messages` em *WhatsApp → Configuration → Webhook fields*.

### Mensagem não chega (fora da janela de 24h)

**Causa:** a Meta só permite texto livre dentro de 24h da última mensagem do usuário.
**Solução:** para disparos proativos, usar um **template aprovado** pela Meta.

### Container não sobe / porta em uso

```bash
# Ver qual processo usa a porta
sudo lsof -i :5678

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