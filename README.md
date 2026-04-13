# Bot WhatsApp — Igreja Batista Graça e Paz

Sistema de automação para WhatsApp com integração ao sistema de gestão Eklesia, usando Evolution API, N8N e PostgreSQL.

---

## Visão Geral

O sistema possui dois módulos principais:

1. **Bot de Atendimento** — responde mensagens recebidas no WhatsApp com menu interativo
2. **Gestão de Escala** — notifica membros escalados, captura confirmações e registra via formulário web

---

## Arquitetura

```
WhatsApp ──► Evolution API ──► N8N Webhooks ──► Workflows ──► PostgreSQL
               (porta 8080)      (porta 5678)                  (porta 5432)
                                                     │
                                               Evolution API ──► WhatsApp
```

**Containers:**
| Serviço        | Porta  | URL                              |
|----------------|--------|----------------------------------|
| Evolution API  | 8080   | http://204.168.230.157:8080      |
| N8N            | 5678   | http://204.168.230.157:5678      |
| PostgreSQL     | 5432   | interno                          |
| Portainer      | 9000   | http://204.168.230.157:9000      |
| Nginx (form)   | 3001   | http://204.168.230.157:3001      |

---

## Pré-requisitos

- Docker e Docker Compose instalados
- Linux (testado no Ubuntu 22.04+)

---

## Instalação do Zero

### 1. Clone o repositório

```bash
git clone <url-do-repositorio> gracapaz
cd gracapaz
```

### 2. Configure o arquivo .env

```bash
cp .env.example .env
nano .env
```

Variáveis críticas:

```env
POSTGRES_PASSWORD=sua_senha_forte
EVOLUTION_API_KEY=sua_global_api_key
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=sua_senha_n8n

# CRÍTICO: sem esta variável o Baileys não gera QR Code (fica em loop)
CONFIG_SESSION_PHONE_VERSION=2.3000.1033846690
```

### 3. Suba os containers

```bash
docker-compose up -d
```

### 4. Suba o container do formulário web

```bash
mkdir -p /opt/gracapaz-form
cp form-escala.html /opt/gracapaz-form/index.html
docker run -d --name form-escala --restart unless-stopped -p 3001:80 -v /opt/gracapaz-form:/usr/share/nginx/html:ro nginx:alpine
```

---

## Banco de Dados (PostgreSQL)

### Tabelas

```sql
-- Membros sincronizados do Eklesia
CREATE TABLE gp_membros (
    id               SERIAL PRIMARY KEY,
    codigo           INTEGER UNIQUE NOT NULL,
    nome             TEXT NOT NULL,
    celular          TEXT,
    celular_whatsapp TEXT,   -- formato: 556192559487
    email            TEXT,
    sexo             TEXT,
    arrolamento      TEXT,
    data_arrolamento DATE,
    igreja           TEXT,
    sincronizado_em  TIMESTAMP DEFAULT NOW()
);

-- Escalas de serviço
CREATE TABLE gp_escala (
    id               SERIAL PRIMARY KEY,
    membro_nome      TEXT NOT NULL,
    celular_whatsapp TEXT NOT NULL,
    funcao           TEXT NOT NULL,
    evento           TEXT NOT NULL,
    data_evento      DATE NOT NULL,
    hora_evento      TEXT,
    status           TEXT DEFAULT 'pendente',  -- pendente | enviado | confirmado | recusado
    criado_por       TEXT,
    enviado_em       TIMESTAMP,
    criado_em        TIMESTAMP DEFAULT NOW()
);
```

---

## Workflows N8N

### 1. Bot Igreja - Menu Principal

**Arquivo:** `workflows/bot-menu-principal.json`
**Webhook:** `POST /webhook/gracapaz`

Recebe todas as mensagens do WhatsApp via Evolution API. Se a mensagem for do tipo `messages.upsert` e não for enviada pela própria igreja:

- Exibe menu personalizado com o nome do membro: *"Olá, João! Seja bem-vindo(a)..."*
- Rota opções 1–7 para respostas específicas (horários, eventos, PIX, etc.)
- Mensagens que não são opções do menu recebem o menu de boas-vindas

**Fluxo:**
```
Webhook ──► Filtrar (IF) ──► Extrair Dados ──► Switch (opção 1-7 ou menu)
```

---

### 2. Eklesia - Sincronizar Membros

**Arquivo:** `workflows/eklesia-sync-membros.json`
**Trigger:** Manual

Busca membros da API do Eklesia (paginado, 100 por página) e salva/atualiza na tabela `gp_membros`.

**Filtragem:** importa apenas membros **ativos** — exclui qualquer arrolamento que começa com `DEMISSAO`, além de `CRIANÇAS APRESENTADAS NA IGREJA` e `FAMILIAS ASSISTIDAS PELA IGREJA`.

**Como executar:**
1. Abrir workflow no N8N
2. Clicar em "Test workflow" (executa as ~10 páginas com intervalo de 1,5s entre chamadas)
3. Resultado: ~466 membros ativos inseridos/atualizados

---

### 3. Eklesia - API Buscar Membro

**Arquivo:** `workflows/eklesia-buscar-membro-api.json`
**Webhook:** `GET /webhook/buscar-membro?q=<nome>`

API interna usada pelo formulário de escala para autocomplete. Retorna até 10 membros com nome e celular_whatsapp que correspondam à busca.

**Exemplo:**
```
GET /webhook/buscar-membro?q=rafael
→ [{"nome":"Rafael Brenner","celular_whatsapp":"556192559487"},...]
```

---

### 4. Eklesia - Form Escala Submit

**Arquivo:** `workflows/eklesia-form-escala-submit.json`
**Webhook:** `POST /webhook/form-escala-submit`

Recebe dados do formulário HTML e insere uma nova escala na tabela `gp_escala` com status `pendente`.

**Campos recebidos:** `nome`, `celular`, `funcao`, `evento`, `data`, `hora`, `registrado_por`

---

### 5. Eklesia - Notificação de Escala via WhatsApp

**Arquivo:** `workflows/eklesia-notificacao-escala.json`
**Schedule:** Segunda a Sexta, 9h

Busca todas as escalas com `status = 'pendente'` e envia mensagem WhatsApp para cada membro com os detalhes da escala e instruções para responder SIM ou NÃO.

Após enviar todas as mensagens, atualiza o status de todas para `enviado`.

**Mensagem enviada:**
```
Olá João! 🙏

Você está na escala da nossa igreja:

📋 *Culto da Família*
🎯 Função: *Louvor*
📅 Data: *20/04/2026*
🕐 Horário: *19:00*

Confirma sua presença? Responda:
✅ *SIM* — Confirmado
❌ *NÃO* — Não poderei ir

_Deus abençoe! — Igreja Batista Graça e Paz_
```

> `continueOnFail: true` no nó de envio — se um número não estiver no WhatsApp, o workflow continua para o próximo.

---

### 6. Eklesia - Capturar Respostas de Escala

**Arquivo:** `workflows/eklesia-capturar-respostas.json`
**Webhook:** `POST /webhook/escala-gateway`

Recebe todas as mensagens do WhatsApp (via webhook secundário configurado na Evolution API). Processa respostas de confirmação de escala.

**Fluxo:**
```
Webhook ──► Filtrar mensagens recebidas
              ├── SIM / NÃO → Buscar na Escala → Atualizar status → Responder membro
              └── Outros    → Encaminhar ao Bot (/webhook/gracapaz)
```

**Lógica de identificação do membro:**
- Se `remoteJid` termina com `@s.whatsapp.net`: extrai o número e busca por `celular_whatsapp`
- Se `remoteJid` termina com `@lid` (privacidade ativada): usa `pushName` com ILIKE no `membro_nome`

**Resposta confirmado:**
```
✅ Presença *confirmada*, João!

Estamos te esperando:
📋 *Culto da Família*
🎯 Função: *Louvor*
📅 Data: *20/04/2026*

Que Deus abençoe seu serviço! 🙏
_Igreja Batista Graça e Paz_
```

---

## Formulário de Escala

**URL:** http://204.168.230.157:3001
**Arquivo:** `form-escala.html`

Formulário HTML servido via nginx para registrar membros na escala.

**Funcionalidades:**
- Autocomplete de nome: ao digitar 2+ caracteres, consulta a API e exibe lista de membros
- Ao selecionar o membro, o campo de celular é preenchido automaticamente
- Validação: impede envio se o nome não foi selecionado do autocomplete
- Campos: Nome do Membro, Função, Evento, Data, Horário, Registrado por

---

## Configuração da Evolution API

### Instância WhatsApp

| Campo             | Valor           |
|-------------------|-----------------|
| Nome da instância | `gracapaz`      |
| Número WhatsApp   | `5561920039423` |

### Webhooks configurados

O sistema usa **dois webhooks** na Evolution API para separar o bot do gateway de escala:

```bash
# Webhook principal do bot
curl -X POST http://localhost:8080/webhook/set/gracapaz \
  -H "apikey: SEU_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "http://n8n:5678/webhook/gracapaz",
    "webhook_by_events": false,
    "events": ["MESSAGES_UPSERT"]
  }'
```

O gateway de escala (`/webhook/escala-gateway`) recebe as mesmas mensagens via encaminhamento interno do workflow do bot.

---

## Patch LID — OBRIGATÓRIO

O WhatsApp usa JIDs no formato `@lid` para contatos com privacidade ativada.
A Evolution API v2.2.3 rejeita esses JIDs por padrão.

O arquivo `patches/main.js` contém o patch aplicado. O `docker-compose.yml` monta automaticamente:

```yaml
volumes:
  - ./patches/main.js:/evolution/dist/main.js:ro
```

**O que o patch faz:** na função `whatsappNumber()`, se o JID contém `@lid`, retorna `exists: true` sem chamar `onWhatsApp()`. O Baileys suporta envio nativo para `@lid`.

---

## Importar Workflows no N8N

A forma mais confiável é importar pela UI do N8N:

1. Acesse http://204.168.230.157:5678
2. Menu → **Workflows** → **Import from file**
3. Selecione o arquivo `.json` desejado
4. Após importar, configure as credenciais (PostgreSQL e API Key da Evolution)

> `n8n import:workflow` via CLI pode falhar com FK constraint na v1.123.4 — use a UI.

### Configurar credencial PostgreSQL

Cada workflow de banco de dados usa a credencial `"PostgreSQL Igreja"`. Crie uma vez:

1. **Credentials** → **New** → **PostgreSQL**
2. Host: `postgres`, Port: `5432`, Database: `gracapaz`, User/Password conforme `.env`
3. Copie o ID gerado e substitua `ADICIONAR_CREDENCIAL_POSTGRES` nos workflows

---

## Comandos Úteis

```bash
# Status dos containers
docker-compose ps
docker ps

# Logs em tempo real
docker-compose logs -f n8n
docker-compose logs -f evolution-api

# Reiniciar N8N (necessário após lentidão ou travamento de execuções)
docker restart n8n

# Ver escalas pendentes
docker exec postgres psql -U root -d gracapaz \
  -c "SELECT membro_nome, funcao, data_evento, status FROM gp_escala ORDER BY data_evento;"

# Ver membros sincronizados
docker exec postgres psql -U root -d gracapaz \
  -c "SELECT COUNT(*), arrolamento FROM gp_membros GROUP BY arrolamento ORDER BY count DESC;"

# Recriar container do formulário
docker rm -f form-escala
docker run -d --name form-escala --restart unless-stopped -p 3001:80 -v /opt/gracapaz-form:/usr/share/nginx/html:ro nginx:alpine
```

---

## Problemas Conhecidos e Soluções

### QR Code não aparece (loop infinito)
**Causa:** variável `CONFIG_SESSION_PHONE_VERSION` ausente.
**Solução:** adicionar `CONFIG_SESSION_PHONE_VERSION=2.3000.1033846690` no `.env` e reiniciar.

### Mensagem não captura resposta SIM/NÃO de certos contatos
**Causa:** WhatsApp envia `remoteJid` no formato `@lid` (privacidade ativada) — impossível extrair número.
**Solução:** o workflow usa `pushName` (nome exibido no WhatsApp) com ILIKE para buscar o membro no banco. Funciona desde que o nome no Eklesia seja próximo ao nome exibido no WhatsApp.

### Emojis no nome do WhatsApp quebram a busca ILIKE
**Causa:** `pushName` como "Maria Silva💖" não bate com "Maria Silva" no banco.
**Solução:** o código já strip emojis com `replace(/[^\p{L}\s]/gu, '')` antes de buscar.

### Evolution API retorna 400 ao enviar para número sem WhatsApp
**Causa:** número cadastrado não tem conta WhatsApp ativa.
**Solução:** `continueOnFail: true` no nó "Enviar WhatsApp" — o workflow continua para o próximo membro.

### `n8n import:workflow` falha com FK constraint
**Causa:** bug com tabela `workflow_publish_history` na v1.123.4.
**Solução:** importar via UI do N8N.

### Switch fallback não funciona (`fallbackOutput: "extra"`)
**Causa:** bug no N8N v1.123.4.
**Solução:** usar regra catch-all com `operation: "exists"` como última regra do Switch.

### Execuções do N8N travando / PostgreSQL sem resposta
**Causa:** conexões acumuladas no pool.
**Solução:** `docker restart n8n`

---

## Estrutura de Arquivos

```
gracapaz/
├── docker-compose.yml                        # Containers principais
├── .env                                      # Credenciais (NÃO commitar!)
├── .env.example                              # Modelo de configuração
├── .gitignore
├── README.md
├── form-escala.html                          # Formulário de registro de escala
├── patches/
│   └── main.js                               # Patch LID para Evolution API
└── workflows/
    ├── bot-menu-principal.json               # Bot de atendimento WhatsApp
    ├── eklesia-sync-membros.json             # Sincronização de membros do Eklesia
    ├── eklesia-buscar-membro-api.json        # API autocomplete para o formulário
    ├── eklesia-form-escala-submit.json       # Recebe submit do formulário
    ├── eklesia-notificacao-escala.json       # Envia notificações de escala (Seg-Sex 9h)
    └── eklesia-capturar-respostas.json       # Captura SIM/NÃO e atualiza banco
```

---

## Segurança

- **Nunca** commite o arquivo `.env`
- O `.gitignore` já protege `.env` e arquivos com dados sensíveis
- Para HTTPS: configurar Nginx Proxy Manager com certificado Let's Encrypt usando o domínio registrado no Registro.br
- Troque todos os tokens e senhas ao replicar em outro ambiente
