# Bot WhatsApp — Igreja Batista Graça e Paz

Sistema de automação para WhatsApp com integração ao sistema de gestão Eklesia, usando o **WhatsApp Cloud API (Meta — canal oficial)**, N8N e PostgreSQL.

> **Migração concluída:** o projeto deixou de usar a Evolution API (Baileys, não-oficial) e
> passou a usar o **canal oficial da Meta**. Setup do zero em **[META_SETUP.md](META_SETUP.md)**.

---

## Visão Geral

O sistema possui dois módulos principais:

1. **Bot de Atendimento** — responde mensagens recebidas no WhatsApp com menu interativo
2. **Gestão de Escala** — notifica membros escalados, captura confirmações e registra via formulário web

---

## Arquitetura

```
WhatsApp ──► Meta Cloud API ──► N8N Webhook ──► Workflows ──► PostgreSQL
            (graph.facebook.com)  (/webhook/whatsapp)          (porta 5432)
                    ▲                     │
                    └──── envio (Graph API) ◄── N8N HTTP nodes
```

A Meta entrega as mensagens recebidas no webhook do N8N (`POST /webhook/whatsapp`) e o N8N
responde enviando texto de volta via `POST graph.facebook.com/<versão>/<PHONE_NUMBER_ID>/messages`.

**Containers:**
| Serviço        | Porta  | URL                              |
|----------------|--------|----------------------------------|
| N8N            | 5678   | http://SEU_IP:5678      |
| PostgreSQL     | 5432   | interno                          |
| pgAdmin        | 5050   | http://SEU_IP:5050      |
| Nginx (form)   | 3001   | http://SEU_IP:3001      |

> Não há mais container da Evolution API. A "ponte" com o WhatsApp agora é a Meta (na nuvem).

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
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=sua_senha_n8n

# WhatsApp Cloud API (Meta) — ver META_SETUP.md para obter estes valores
GRAPH_API_VERSION=v21.0
WHATSAPP_PHONE_NUMBER_ID=...
WHATSAPP_WABA_ID=...
WHATSAPP_TOKEN=...
WHATSAPP_VERIFY_TOKEN=...
```

> O setup completo da Meta (criar app, registrar o número (61) 3028-0665, gerar o token
> permanente e configurar o webhook) está em **[META_SETUP.md](META_SETUP.md)**.

### 3. Suba os containers

```bash
docker-compose up -d
```

O formulário web já está incluso no `docker-compose.yml` como serviço `form-escala` (nginx na porta 3001) — não é necessário nenhum passo adicional.

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
    celular_whatsapp TEXT,   -- formato: 5561XXXXXXXXX
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
**Webhooks:** `GET /webhook/whatsapp` (verificação) · `POST /webhook/whatsapp` (mensagens)

Recebe as mensagens do WhatsApp via Meta Cloud API. O webhook GET responde o `hub.challenge`
para a Meta validar a URL. O POST processa mensagens recebidas (ignora os *status callbacks*
de entregue/lido):

- Exibe menu personalizado com o nome do membro: *"Olá, João! Seja bem-vindo(a)..."*
- Rota opções 1–7 para respostas específicas (horários, eventos, PIX, etc.)
- Mensagens que não são opções do menu recebem o menu de boas-vindas
- O envio é feito via `POST graph.facebook.com/<versão>/<PHONE_NUMBER_ID>/messages`
  (credencial Header Auth `WhatsApp Cloud API` com `Authorization: Bearer <token>`)

**Fluxo:**
```
GET  Webhook ──► Responder Challenge (hub.challenge)
POST Webhook ──► Filtrar (tem messages?) ──► Extrair Dados ──► Switch (opção 1-7 ou menu) ──► Enviar (Graph API)
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
→ [{"nome":"João Silva","celular_whatsapp":"5561XXXXXXXXX"},...]
```

---

### 4. Eklesia - Form Escala Submit

**Arquivo:** `workflows/eklesia-form-escala-submit.json`
**Webhook:** `POST /webhook/form-escala-submit`

Recebe dados do formulário HTML e insere uma nova escala na tabela `gp_escala` com status `pendente`.

**Campos recebidos:** `nome`, `celular`, `funcao`, `evento`, `data`, `hora`, `registrado_por`

---

### 5. Eklesia - Notificação de Escala via WhatsApp

> ⚠️ **Não migrado para a Meta.** Os workflows de escala (este e o #6) ainda usam o formato
> da Evolution API e **não estão ativos**. Para reativá-los, os nós de envio precisam ser
> adaptados para a Graph API (mesmo padrão do `bot-menu-principal`) e o recebimento de
> respostas precisa ser integrado ao webhook único da Meta (`/webhook/whatsapp`).

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

**URL:** http://SEU_IP:3001
**Arquivo:** `form-escala.html`

Formulário HTML servido via nginx para registrar membros na escala.

**Funcionalidades:**
- Autocomplete de nome: ao digitar 2+ caracteres, consulta a API e exibe lista de membros
- Ao selecionar o membro, o campo de celular é preenchido automaticamente
- Validação: impede envio se o nome não foi selecionado do autocomplete
- Campos: Nome do Membro, Função, Evento, Data, Horário, Registrado por

---

## Configuração da Meta (WhatsApp Cloud API)

Toda a configuração do canal oficial — criar o app, registrar o número **(61) 3028-0665**,
gerar o token permanente e cadastrar o webhook — está documentada em
**[META_SETUP.md](META_SETUP.md)**.

Resumo dos valores no `.env`:

| Variável                   | Origem                                    |
|----------------------------|-------------------------------------------|
| `WHATSAPP_PHONE_NUMBER_ID` | WhatsApp → API Setup                      |
| `WHATSAPP_WABA_ID`         | WhatsApp → API Setup                      |
| `WHATSAPP_TOKEN`           | Token permanente do System User           |
| `WHATSAPP_VERIFY_TOKEN`    | String aleatória (igual à do webhook Meta)|

**Webhook na Meta:** `Callback URL = https://n8n.gracaepazdf.org.br/webhook/whatsapp`,
*Verify token* = `WHATSAPP_VERIFY_TOKEN`, campo assinado = `messages`.

---

## Importar Workflows no N8N

A forma mais confiável é importar pela UI do N8N:

1. Acesse http://SEU_IP:5678
2. Menu → **Workflows** → **Import from file**
3. Selecione o arquivo `.json` desejado
4. Após importar, configure as credenciais (PostgreSQL e a credencial Header Auth da Meta)

> `n8n import:workflow` via CLI pode falhar com FK constraint na v1.123.4 — use a UI.

### Configurar credencial do WhatsApp Cloud API

Os nós de envio usam a credencial **Header Auth** chamada `WhatsApp Cloud API`:

1. **Credentials** → **New** → **Header Auth**
2. Name: `Authorization` · Value: `Bearer <WHATSAPP_TOKEN>`
3. Abra cada nó de envio do workflow `bot-menu-principal` e selecione essa credencial. ⚠️ Nós
   importados não herdam a credencial automaticamente — reabra e reconecte cada um.

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

# Reiniciar N8N (necessário após lentidão ou travamento de execuções)
docker restart n8n

# Ver escalas pendentes
docker exec postgres psql -U root -d evolution \
  -c "SELECT membro_nome, funcao, data_evento, status FROM gp_escala ORDER BY data_evento;"

# Ver membros sincronizados
docker exec postgres psql -U root -d evolution \
  -c "SELECT COUNT(*), arrolamento FROM gp_membros GROUP BY arrolamento ORDER BY count DESC;"

# Recriar container do formulário
docker-compose up -d --force-recreate form-escala
```

---

## Problemas Conhecidos e Soluções

### Webhook da Meta não verifica ("Verify and Save" falha)
**Causa:** workflow inativo, `WHATSAPP_VERIFY_TOKEN` diferente do cadastrado na Meta, ou URL
usando `/webhook-test/` em vez de `/webhook/`.
**Solução:** ativar o workflow, conferir que o token bate, e usar a URL de produção
`https://n8n.gracaepazdf.org.br/webhook/whatsapp`.

### Bot responde aos próprios envios / responde "entregue/lido"
**Causa:** processamento dos *status callbacks* da Meta.
**Solução:** o filtro "Somente Mensagens Recebidas" só passa quando existe
`entry[0].changes[0].value.messages` — status callbacks (que trazem `statuses`) são ignorados.

### Erro 401/403 ao enviar mensagem
**Causa:** `WHATSAPP_TOKEN` inválido/expirado, ou a credencial Header Auth não está com
`Bearer <token>`.
**Solução:** usar o **token permanente do System User** (não o temporário de 24h) e conferir o
valor `Authorization: Bearer <token>` na credencial `WhatsApp Cloud API`.

### Mensagem não chega ao destinatário (fora da janela de 24h)
**Causa:** a Meta só permite texto livre dentro de 24h da última mensagem do usuário.
**Solução:** para disparos proativos, criar e usar um **template aprovado** pela Meta.

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
├── META_SETUP.md                             # Guia do zero: WhatsApp Cloud API (Meta)
├── form-escala.html                          # Formulário de registro de escala
├── scripts/
│   ├── init-eklesia-db.sql                   # Criação das tabelas gp_membros e gp_escala
│   ├── criar-tabela-bot-estados.sql          # Tabela bot_estados (máquina de estados)
│   ├── 003_migrate_hora_tipo.sql             # Migration: VARCHAR → TIME em hora_evento
│   ├── 004_add_fk_escala.sql                 # Migration: FK gp_escala → gp_membros
│   └── migrate.sh                            # Aplica todas as migrations em ordem
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
