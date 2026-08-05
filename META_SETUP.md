# Setup do WhatsApp Cloud API (Meta) — do zero

Guia para configurar o **canal oficial da Meta** que substitui a Evolution API.
Número dedicado deste projeto: **(61) 3028-0665** → formato internacional `556130280665`.

> ⚠️ Por ser um número **fixo** (não celular), a verificação na Meta deve ser feita por
> **ligação de voz** ("Phone call"), não por SMS. O número também **não pode estar ativo**
> no aplicativo WhatsApp comum/Business.

---

## Visão geral do que vamos obter

Ao final, você terá 4 valores para colocar no `.env`:

| Variável                    | Onde aparece na Meta                     |
|-----------------------------|------------------------------------------|
| `WHATSAPP_PHONE_NUMBER_ID`  | WhatsApp → API Setup (Phone number ID)   |
| `WHATSAPP_WABA_ID`          | WhatsApp → API Setup (WhatsApp Business Account ID) |
| `WHATSAPP_TOKEN`            | Token permanente do System User          |
| `WHATSAPP_VERIFY_TOKEN`     | Você inventa (string aleatória secreta)  |

---

## Passo 1 — Conta Meta Business

1. Acesse <https://business.facebook.com> e crie/entre em uma conta **Meta Business**.
2. Em *Configurações do Negócio* (Business Settings), confirme que você é **admin**.

## Passo 2 — Criar o App

1. Acesse <https://developers.facebook.com/apps> → **Create App**.
2. Tipo do app: **Business**.
3. Após criar, em *Add products*, adicione o produto **WhatsApp**.

## Passo 3 — Registrar o número (61) 3028-0665

1. No app: **WhatsApp → API Setup**.
2. Em *From*, clique em **Add phone number** e cadastre o número **(61) 3028-0665**
   (informe o nome de exibição do negócio quando pedido).
3. Na verificação, **escolha "Phone call" (ligação de voz)** — chega um código por chamada.
4. Confirme o código. O número fica registrado na sua **WhatsApp Business Account (WABA)**.

## Passo 4 — Coletar os IDs

Ainda em **WhatsApp → API Setup**, anote:
- **Phone number ID** → vai em `WHATSAPP_PHONE_NUMBER_ID`.
- **WhatsApp Business Account ID** → vai em `WHATSAPP_WABA_ID`.

> O token que aparece nessa tela (*temporary access token*) **expira em 24h** — serve só
> para testes rápidos. Para produção, gere o token permanente no passo 5.

## Passo 5 — Token permanente (System User)

1. *Business Settings* → **Users → System Users** → **Add**.
   - Nome: ex. `bot-gracapaz`; papel: **Admin**.
2. Selecione o System User criado → **Add Assets** → escolha o **App** (e a WABA) com
   permissão total (Manage/Develop).
3. Clique em **Generate New Token**:
   - App: selecione o app do passo 2.
   - Escopos (permissions): marque **`whatsapp_business_messaging`** e
     **`whatsapp_business_management`**.
4. Copie o token gerado → vai em `WHATSAPP_TOKEN`. **Esse token não expira.**

## Passo 6 — Configurar o `.env` e subir a stack

No servidor, preencha o `.env` (ver `.env.example`):

```env
GRAPH_API_VERSION=v21.0
WHATSAPP_PHONE_NUMBER_ID=<do passo 4>
WHATSAPP_WABA_ID=<do passo 4>
WHATSAPP_TOKEN=<do passo 5>
WHATSAPP_VERIFY_TOKEN=<invente uma string aleatória, ex: openssl rand -hex 16>
```

Suba os containers e **ative** o workflow `bot-menu-principal` no N8N (ver `README.md`).

## Passo 7 — Credencial no N8N (Bearer token)

Os nós de envio usam uma credencial **HTTP Header Auth**:

1. No N8N: **Credentials → New → Header Auth**.
2. Nome: `WhatsApp Cloud API`.
3. **Name:** `Authorization`  ·  **Value:** `Bearer <WHATSAPP_TOKEN>` (cole o token do passo 5).
4. Abra cada nó de envio do workflow, selecione essa credencial e **salve**.
   ⚠️ Nós importados não herdam a credencial automaticamente — é preciso reabrir e reconectar.

## Passo 8 — Configurar o Webhook na Meta

1. No app: **WhatsApp → Configuration → Webhook** → **Edit**.
2. **Callback URL:** `https://n8n.gracaepazdf.org.br/webhook/whatsapp`
3. **Verify token:** o mesmo valor de `WHATSAPP_VERIFY_TOKEN` do `.env`.
4. Clique **Verify and Save**. A Meta faz um `GET` na URL; o workflow responde o
   `hub.challenge` e a verificação passa.
   - ⚠️ O workflow precisa estar **ativo** (URL de produção `/webhook/`, não `/webhook-test/`).
5. Em **Webhook fields**, clique em **Manage** e assine o campo **`messages`**.

## Passo 9 — Testar

1. No painel API Setup, em *To*, adicione um número de teste (pré-cadastrado) e envie a
   mensagem template inicial OU mande uma mensagem do seu celular para o (61) 3028-0665.
2. Mande qualquer texto → o bot deve responder com o menu de boas-vindas.
3. Teste as opções 1–6, os eventos 31/32/34 e o `0` (voltar/cancelar).

## Passo 10 — Ir para produção

- **Verificação do negócio** (Business Verification) em *Business Settings → Security Center*.
- Adicionar **método de pagamento** na WABA.
- Enquanto não verificado, o número só envia para **até 5 destinatários** pré-cadastrados.

---

## Observações importantes

- **Janela de 24h:** fora de 24h da última mensagem do usuário, só é possível enviar
  *templates aprovados* pela Meta. O bot é reativo (responde a quem escreve), então opera
  dentro da janela. Disparos proativos (avisos, campanhas) exigem template aprovado.
- **9º dígito (Brasil):** ao responder, o workflow devolve exatamente o número recebido no
  campo `from` — não reconstrói o número — evitando o problema do 9º dígito.
- **Status callbacks:** a Meta envia eventos de "entregue/lido" no mesmo webhook; o filtro do
  workflow ignora esses (só processa quando há `messages`).
