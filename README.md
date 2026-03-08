# Bot WhatsApp — Igreja Batista Graça e Paz

Sistema de automação para WhatsApp usando Evolution API v2.2.3, N8N e PostgreSQL.

---

## Arquitetura

```
WhatsApp ──► Evolution API ──► N8N Webhook ──► Workflow ──► Evolution API ──► WhatsApp
                (porta 8080)     (porta 5678)
```

**Containers:**
| Serviço        | Porta  | URL                        |
|----------------|--------|----------------------------|
| Evolution API  | 8080   | http://localhost:8080      |
| N8N            | 5678   | http://localhost:5678      |
| PostgreSQL     | 5432   | interno                    |
| Portainer      | 9000   | http://localhost:9000      |

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

Preencha todas as variáveis. As críticas são:

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

Aguarde ~30 segundos para todos iniciarem.

---

## Configuração da Evolution API

### Criar instância WhatsApp

```bash
curl -X POST http://localhost:8080/instance/create \
  -H "Content-Type: application/json" \
  -H "apikey: SUA_GLOBAL_API_KEY" \
  -d '{
    "instanceName": "gracapaz",
    "token": "SEU_TOKEN_DA_INSTANCIA",
    "qrcode": true
  }'
```

### Conectar WhatsApp via QR Code

Acesse http://localhost:8080/manager, selecione a instância `gracapaz` e escaneie o QR Code.

### Configurar Webhook para o N8N

```bash
curl -X POST http://localhost:8080/webhook/set/gracapaz \
  -H "Content-Type: application/json" \
  -H "apikey: SEU_TOKEN_DA_INSTANCIA" \
  -d '{
    "url": "http://n8n:5678/webhook/gracapaz",
    "webhook_by_events": false,
    "webhook_base64": false,
    "events": ["MESSAGES_UPSERT"]
  }'
```

> ⚠️ Use `http://n8n:5678` (nome do container), não `localhost`.

---

## Patch LID — OBRIGATÓRIO

O WhatsApp usa JIDs no formato `@lid` para contatos com privacidade ativada.
A Evolution API v2.2.3 rejeita esses JIDs por padrão. O patch corrige isso.

O arquivo `patches/main.js` já está no repositório com o patch aplicado.
O `docker-compose.yml` monta esse arquivo automaticamente:

```yaml
volumes:
  - ./patches/main.js:/evolution/dist/main.js:ro
```

**O que o patch faz:** adiciona um bypass na função `whatsappNumber()` — se o JID contém `@lid`, retorna `exists: true` sem chamar `onWhatsApp()`. O Baileys suporta envio nativo para `@lid`.

Após qualquer atualização da imagem Docker, o patch continua ativo pois é montado via volume.

---

## Configuração do N8N

### 1. Criar credencial de autenticação

Acesse http://localhost:5678 → **Credentials** → **New** → **Header Auth**

- **Name:** `Header Auth account`
- **Name (header):** `apikey`
- **Value:** `SEU_TOKEN_DA_INSTANCIA`

> O ID da credencial gerado pelo N8N precisa ser atualizado no workflow (veja abaixo).

### 2. Importar o workflow

⚠️ **O comando `n8n import:workflow` não funciona** nesta versão por um bug com `workflow_publish_history`. Use SQL direto:

```bash
# Copiar arquivo para o container postgres
docker cp workflows/bot-menu-principal.json postgres:/tmp/bot-menu-principal.json

# Verificar se já existe um workflow
docker exec postgres psql -U root -d n8n \
  -c "SELECT id, name FROM workflow_entity;"

# Se não existir, inserir:
docker exec postgres psql -U root -d n8n -c "
INSERT INTO workflow_entity (id, name, nodes, connections, active, settings, \"staticData\", tags, \"updatedAt\", \"createdAt\")
SELECT
  'o6yPgQ34jJPDnduM',
  'Bot Igreja - Menu Principal',
  (SELECT nodes FROM json_populate_record(null::workflow_entity, pg_read_file('/tmp/bot-menu-principal.json')::json)),
  ...
"

# Se já existir, atualizar:
docker exec postgres bash -c "
psql -U root -d n8n << 'EOF'
UPDATE workflow_entity
SET nodes = (SELECT (content::json->>'nodes')::jsonb FROM (SELECT pg_read_file('/tmp/bot-menu-principal.json') AS content) t),
    connections = (SELECT (content::json->>'connections')::jsonb FROM (SELECT pg_read_file('/tmp/bot-menu-principal.json') AS content) t),
    \"updatedAt\" = NOW()
WHERE name = 'Bot Igreja - Menu Principal';
EOF
"
```

> Na prática, o mais fácil é criar o workflow manualmente na UI do N8N seguindo a estrutura do arquivo `workflows/bot-menu-principal.json`.

### 3. Atualizar ID da credencial no workflow

Depois de criar a credencial no N8N, pegue o ID gerado:

```bash
docker exec postgres psql -U root -d n8n \
  -c "SELECT id, name FROM credentials_entity;"
```

Substitua o ID em todos os nós HTTP do workflow:
```json
"credentials": {
  "httpHeaderAuth": {
    "id": "ID_DA_SUA_CREDENCIAL",
    "name": "Header Auth account"
  }
}
```

### 4. Ativar o workflow

No N8N, abra o workflow e clique em **Active** (toggle no canto superior direito).

---

## Estrutura do Workflow

```
Webhook (POST /gracapaz)
  └─► Somente Mensagens Recebidas (IF)
        ├─► [true]  Extrair Dados da Mensagem (SET)
        │     └─► Roteador de Opcoes (SWITCH)
        │           ├─► 1 → Enviar Horarios
        │           ├─► 2 → Enviar Cursos e Celulas
        │           ├─► 3 → Enviar Eventos
        │           ├─► 4 → Enviar Inscricoes
        │           ├─► 5 → Enviar Dizimos e Ofertas
        │           ├─► 6 → Enviar Gabinete Pastoral
        │           ├─► 7 → Enviar Falar com Equipe
        │           └─► (qualquer outro) → Enviar Menu de Boas-vindas
        └─► [false] Responder 200 OK
```

**⚠️ Atenção Switch Node:** `fallbackOutput: "extra"` **não funciona** no N8N v1.123.4.
Use uma regra catch-all com `operation: "exists"` como última regra antes do menu.

---

## Menu do Bot

```
Olá! Seja bem-vindo à Igreja Batista Graça e Paz 🙌

1️⃣ Dias e horários dos cultos
2️⃣ Cursos, seminários e células
3️⃣ Eventos 2026
4️⃣ Informações sobre inscrições
5️⃣ Dízimos e Ofertas
6️⃣ Gabinete Pastoral
7️⃣ Falar com nossa equipe
```

---

## Informações da Igreja

| Campo        | Valor                         |
|--------------|-------------------------------|
| PIX (CNPJ)   | 14.853.562/0001-92            |
| Nome PIX     | Igreja Batista Graça e Paz    |

**Cultos:**
- Domingo 19h — Culto da Família
- Sábado 19h — Culto da Juventude (Deep Life)
- Quinta-feira 20h — Célula de Jovens
- Primeira segunda do mês 20h — Culto das Mulheres
- Última sexta do mês 20h — Culto dos Homens
- Primeiro sábado do mês 8h–18h — Dia com Deus

---

## Dados da Instância (salvar em local seguro)

| Campo              | Valor                                      |
|--------------------|--------------------------------------------|
| Nome da instância  | `gracapaz`                                 |
| Número WhatsApp    | `5561920039423`                            |
| Token da instância | (ver arquivo `.env`)                       |
| Global API Key     | (ver arquivo `.env`)                       |

---

## Comandos Úteis

```bash
# Status dos containers
docker-compose ps

# Logs em tempo real
docker-compose logs -f n8n
docker-compose logs -f evolution-api

# Verificar estado da conexão WhatsApp
curl http://localhost:8080/instance/connectionState/gracapaz \
  -H "apikey: SEU_TOKEN"

# Reiniciar N8N (necessário após edições diretas no banco)
docker restart n8n

# Acessar banco de dados
docker exec postgres psql -U root -d n8n

# Ver execuções recentes do workflow
docker exec postgres psql -U root -d n8n \
  -c "SELECT id, status, \"startedAt\" FROM execution_entity ORDER BY id DESC LIMIT 10;"
```

---

## Problemas Conhecidos e Soluções

### QR Code não aparece (loop infinito)
**Causa:** variável `CONFIG_SESSION_PHONE_VERSION` ausente ou incorreta.
**Solução:** adicionar `CONFIG_SESSION_PHONE_VERSION=2.3000.1033846690` no `.env` e reiniciar.

### Mensagens de contatos com `@lid` não são entregues
**Causa:** Evolution API rejeita JIDs `@lid`.
**Solução:** patch em `patches/main.js` (já incluído no repositório).

### `n8n import:workflow` falha com FK constraint
**Causa:** bug com tabela `workflow_publish_history` na v1.123.4.
**Solução:** importar via UI do N8N ou atualizar diretamente via SQL.

### Switch fallback não funciona (`fallbackOutput: "extra"`)
**Causa:** bug no N8N v1.123.4.
**Solução:** usar regra catch-all com `operation: "exists"` como última regra do Switch.

### Nó HTTP retorna erro 400 "Bad Request"
**Causa:** credencial não configurada no nó ou número inexistente no WhatsApp.
**Solução:** verificar se todos os nós HTTP têm `credentials` definido com o ID correto.

---

## Estrutura de Arquivos

```
gracapaz/
├── docker-compose.yml          # Configuração dos containers
├── .env                        # Credenciais (NÃO commitar!)
├── .env.example                # Modelo de configuração
├── .gitignore
├── README.md
├── patches/
│   └── main.js                 # Patch LID para Evolution API
└── workflows/
    └── bot-menu-principal.json # Workflow do bot (referência)
```

---

## Segurança

- **Nunca** commite o arquivo `.env`
- O `.gitignore` já protege `.env` e `patches/main.js` com dados sensíveis
- Troque todos os tokens e senhas ao replicar em outro ambiente