# 🔧 Alternativas ao EasyPanel para Windows

O EasyPanel tem problemas de compatibilidade conhecidos com Docker Desktop no Windows. Aqui estão as melhores alternativas:

## ⚠️ Problema do EasyPanel

**Erro**: `TypeError: Invalid version. Must be a string. Got type "object"`

Este é um bug conhecido do EasyPanel onde ele não consegue parsear corretamente a versão do Docker Desktop no Windows.

## ✅ Alternativa 1: Interface Nativa do Evolution API (RECOMENDADO)

A Evolution API já vem com uma interface de gerenciamento embutida!

### Como acessar:

1. Acesse: **http://localhost:8080/manager**
2. Faça login com sua API Key: `sua_chave_api_secreta_aqui`
3. Você terá acesso a:
   - ✅ Criar instâncias do WhatsApp
   - ✅ Escanear QR Code
   - ✅ Gerenciar conexões
   - ✅ Ver logs
   - ✅ Enviar mensagens de teste
   - ✅ Configurar webhooks

### Vantagens:
- Já está incluído (sem precisar instalar nada)
- Específico para Evolution API
- Leve e rápido
- Totalmente funcional

## ✅ Alternativa 2: Portainer

Interface visual completa para gerenciar todos os containers Docker.

### Adicionar ao docker-compose.yml:

```yaml
  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    ports:
      - "9000:9000"
      - "9443:9443"
    volumes:
      - //var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data
    networks:
      - whatsapp-network
    restart: unless-stopped
```

### Iniciar:
```bash
docker-compose up -d portainer
```

### Acessar:
- HTTPS: https://localhost:9443
- HTTP: http://localhost:9000

### Vantagens:
- Interface moderna e intuitiva
- Gerencia todos os containers
- Logs em tempo real
- Terminal integrado
- Estatísticas de recursos
- Totalmente compatível com Windows

## ✅ Alternativa 3: Yacht

Interface minimalista e leve para Docker.

### Adicionar ao docker-compose.yml:

```yaml
  yacht:
    image: selfhostedpro/yacht:latest
    container_name: yacht
    ports:
      - "8000:8000"
    volumes:
      - //var/run/docker.sock:/var/run/docker.sock
      - yacht_data:/config
    networks:
      - whatsapp-network
    restart: unless-stopped
```

### Iniciar:
```bash
docker-compose up -d yacht
```

### Acessar:
- URL: http://localhost:8000
- Usuário padrão: `admin@yacht.local`
- Senha padrão: `pass`

### Vantagens:
- Muito leve
- Interface simples
- Templates para deploys rápidos
- Compatível com Windows

## ✅ Alternativa 4: Dozzle (Logs apenas)

Se você só precisa ver logs em tempo real:

### Adicionar ao docker-compose.yml:

```yaml
  dozzle:
    image: amir20/dozzle:latest
    container_name: dozzle
    ports:
      - "8888:8080"
    volumes:
      - //var/run/docker.sock:/var/run/docker.sock:ro
    networks:
      - whatsapp-network
    restart: unless-stopped
```

### Iniciar:
```bash
docker-compose up -d dozzle
```

### Acessar:
- URL: http://localhost:8888

### Vantagens:
- Específico para logs
- Muito leve
- Interface limpa
- Logs em tempo real com filtros
- Sem necessidade de login

## ✅ Alternativa 5: Docker Desktop GUI

O próprio Docker Desktop tem uma interface integrada!

### Como usar:

1. Abra o **Docker Desktop**
2. Vá em **Containers**
3. Encontre seus containers
4. Clique para ver:
   - Logs
   - Estatísticas
   - Terminal
   - Arquivos

### Vantagens:
- Já está instalado
- Interface nativa
- Totalmente integrado
- Não precisa de porta adicional

## 📊 Comparação

| Feature | Evolution Manager | Portainer | Yacht | Dozzle | Docker Desktop |
|---------|------------------|-----------|-------|--------|----------------|
| Gratuito | ✅ | ✅ | ✅ | ✅ | ✅ |
| Fácil Setup | ✅ | ✅ | ✅ | ✅ | ✅ |
| Específico Evolution | ✅ | ❌ | ❌ | ❌ | ❌ |
| Gerencia Containers | ❌ | ✅ | ✅ | ❌ | ✅ |
| Logs Tempo Real | ✅ | ✅ | ✅ | ✅ | ✅ |
| Terminal Integrado | ❌ | ✅ | ✅ | ❌ | ✅ |
| Stats/Métricas | ✅ | ✅ | ✅ | ❌ | ✅ |
| Windows Compatible | ✅ | ✅ | ✅ | ✅ | ✅ |

## 🎯 Recomendação

**Para gerenciar apenas o Evolution API:**
→ Use a interface nativa: http://localhost:8080/manager

**Para gerenciar todos os containers:**
→ Use Portainer: https://localhost:9443

**Para ver logs rapidamente:**
→ Use Dozzle: http://localhost:8888

**Para desenvolvimento/debug:**
→ Use Docker Desktop GUI (já instalado)

## 🚀 Como Implementar

### Remover EasyPanel:

```bash
docker stop easypanel
docker rm easypanel
docker volume rm graca_paz_easypanel_data
```

### Adicionar Portainer (recomendado):

1. Edite `docker-compose.yml`
2. Substitua a seção `easypanel` por `portainer` (código acima)
3. Adicione o volume:
```yaml
volumes:
  portainer_data:  # adicione esta linha
```
4. Execute:
```bash
docker-compose up -d portainer
```

## 📝 Observações

- **EasyPanel funciona em Linux** (Ubuntu, Debian, etc.)
- No **Windows**, use as alternativas acima
- Para **produção em servidor Linux**, você pode instalar EasyPanel diretamente:
  ```bash
  curl -sSL https://get.easypanel.io | sh
  ```

## 🔗 Links Úteis

- [Evolution API Manager Docs](https://doc.evolution-api.com/)
- [Portainer Docs](https://docs.portainer.io/)
- [Yacht Docs](https://yacht.sh/docs/)
- [Dozzle Docs](https://dozzle.dev/)

---

**Última atualização**: 2026-01-09
