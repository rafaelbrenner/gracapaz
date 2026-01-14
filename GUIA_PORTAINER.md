# 🎛️ Guia Portainer - Administração Visual dos Containers

O Portainer é uma interface web moderna para gerenciar seus containers Docker de forma visual e intuitiva.

## 🚀 Primeiro Acesso

### 1. Acessar o Portainer

Após iniciar os containers, acesse:
- **HTTPS**: https://localhost:9443 (recomendado)
- **HTTP**: http://localhost:9000

### 2. Criar Usuário Admin

Na primeira vez:
1. Digite um **nome de usuário** (ex: admin)
2. Crie uma **senha forte** (mínimo 12 caracteres)
3. Confirme a senha
4. Clique em **Create user**

⚠️ **IMPORTANTE**: Guarde essas credenciais em local seguro!

### 3. Conectar ao Docker Local

1. Selecione **Get Started**
2. O Portainer detectará automaticamente o Docker local
3. Clique no ambiente **local**

## 📊 Gerenciando o Evolution API

### Ver Status do Evolution API

1. No menu lateral, clique em **Containers**
2. Localize o container `evolution-api`
3. Você verá:
   - ✅ Estado: Running/Stopped
   - 📊 Uso de CPU e Memória
   - 🔌 Portas: 8080
   - ⏱️ Tempo de execução

### Ações Rápidas

#### Visualizar Logs
1. Clique no nome **evolution-api**
2. Clique na aba **Logs**
3. Ative **Auto-refresh** para logs em tempo real
4. Use **Search** para filtrar logs específicos

#### Reiniciar Container
1. Selecione o checkbox do `evolution-api`
2. Clique em **Restart**
3. Confirme a ação

#### Parar/Iniciar Container
1. Selecione o container
2. Clique em **Stop** ou **Start**
3. Confirme a ação

#### Acessar Terminal (Console)
1. Clique no nome **evolution-api**
2. Clique em **Console**
3. Selecione **/bin/bash** ou **/bin/sh**
4. Clique em **Connect**
5. Você terá acesso ao terminal do container

### Monitoramento

#### Ver Estatísticas em Tempo Real
1. Clique no nome **evolution-api**
2. Clique na aba **Stats**
3. Visualize:
   - 📈 Uso de CPU (%)
   - 💾 Uso de Memória (MB)
   - 🌐 Tráfego de Rede (TX/RX)
   - 💿 I/O de Disco

#### Inspecionar Configuração
1. Clique no nome **evolution-api**
2. Clique na aba **Inspect**
3. Veja toda a configuração do container em JSON

## 🔧 Operações Avançadas

### Alterar Variáveis de Ambiente

1. Clique no nome **evolution-api**
2. Clique em **Duplicate/Edit**
3. Role até **Environment variables**
4. Adicione/edite as variáveis
5. Clique em **Deploy the container**

⚠️ **Nota**: Isso recriará o container com as novas variáveis.

### Ver Volumes Montados

1. Clique no nome **evolution-api**
2. Clique na aba **Volumes**
3. Você verá:
   - `evolution_instances`: Dados das instâncias WhatsApp
   - `evolution_store`: Armazenamento geral

### Backup de Volumes

1. Menu lateral → **Volumes**
2. Localize `evolution_instances`
3. Clique no nome do volume
4. Clique em **Browse**
5. Você pode baixar arquivos individuais

## 🐳 Gerenciando Todos os Containers

### Dashboard Principal

No **Dashboard** você vê:
- 📦 Total de containers
- 🟢 Containers rodando
- 🔴 Containers parados
- 📊 Uso total de recursos

### Gerenciar Múltiplos Containers

1. **Containers** → Selecione múltiplos containers
2. Ações em lote:
   - Start/Stop/Restart
   - Pause/Unpause
   - Kill
   - Remove

### Stacks (Docker Compose)

1. Menu lateral → **Stacks**
2. Você verá `graca_paz` (seu projeto)
3. Clique para ver todos os serviços
4. Pode parar/iniciar a stack inteira

## 🔍 Troubleshooting via Portainer

### Container não inicia

1. **Containers** → Clique no container problemático
2. **Logs** → Procure por erros
3. **Inspect** → Verifique configuração
4. Se necessário, **Console** para debugar

### Alto Uso de Recursos

1. **Stats** → Identifique o container problemático
2. **Console** → Execute comandos de diagnóstico:
   ```bash
   top        # Ver processos
   df -h      # Ver uso de disco
   free -m    # Ver uso de memória
   ```

### Limpar Containers Parados

1. **Containers** → Filtre por **Stopped**
2. Selecione containers desnecessários
3. Clique em **Remove**

## 🌐 Gerenciando Networks

1. Menu lateral → **Networks**
2. Clique em `graca_paz_whatsapp-network`
3. Veja todos os containers conectados
4. Verifique configurações de rede

## 💾 Gerenciando Volumes

### Ver Uso de Espaço

1. Menu lateral → **Volumes**
2. Veja tamanho de cada volume
3. Identifique volumes grandes:
   - `postgres_data`: Banco de dados
   - `evolution_instances`: Instâncias WhatsApp
   - `n8n_data`: Workflows N8N

### Limpar Volumes Órfãos

1. **Volumes**
2. Filtre por **Unused**
3. Selecione volumes não utilizados
4. Clique em **Remove**

⚠️ **CUIDADO**: Não remova volumes em uso!

## 📸 Criar Backups

### Backup Manual via Portainer

1. **Volumes** → Clique no volume (ex: `evolution_instances`)
2. **Browse** → Navegue pelos arquivos
3. Selecione arquivos/pastas
4. Clique em **Download**

### Snapshot de Container

1. **Containers** → Clique no container
2. **Duplicate/Edit**
3. Isso cria uma cópia das configurações
4. Você pode salvar a configuração como template

## 🔐 Segurança no Portainer

### Alterar Senha Admin

1. Clique no ícone de usuário (canto superior direito)
2. **My account**
3. **Change password**
4. Digite a senha atual e nova senha
5. Clique em **Update password**

### Limitar Acesso

Portainer tem sistema de usuários e times (versão Pro).
Na versão CE (Community), apenas admin tem acesso.

### Proteger com Firewall

Se expor o Portainer externamente:
1. Use apenas HTTPS (porta 9443)
2. Configure firewall para limitar acesso
3. Considere VPN para acesso remoto

## 💡 Dicas Úteis

### Atalhos de Teclado

- `Ctrl + F` na aba Logs: Buscar no log
- `Ctrl + Shift + R`: Refresh automático

### Filtros Rápidos

No **Containers**:
- Filtre por estado: Running, Stopped, Paused
- Filtre por nome: Digite no campo de busca
- Filtre por label

### Notificações

Portainer pode enviar notificações (versão Pro):
- Container parou
- Alto uso de recursos
- Falhas de deploy

### Templates

1. **App Templates** → Templates prontos
2. Use para deployar aplicações rapidamente
3. Crie seus próprios templates personalizados

## 🆘 Comandos Úteis

### Via Console do Portainer

Dentro do container Evolution API:

```bash
# Ver processos rodando
ps aux

# Ver uso de memória
free -h

# Ver logs da aplicação
tail -f /evolution/logs/app.log

# Verificar conectividade
ping postgres
ping redis
ping n8n

# Ver variáveis de ambiente
env | grep EVOLUTION
```

## 🔄 Atualizações

### Atualizar Evolution API

1. **Images** → Encontre `atendai/evolution-api`
2. Clique em **Pull**
3. Aguarde o download da nova versão
4. **Containers** → Selecione `evolution-api`
5. **Recreate**
6. Marque **Pull latest image**
7. Clique em **Recreate**

### Atualizar Todos os Containers

1. **Stacks** → Clique em `graca_paz`
2. Clique em **Update**
3. Marque **Pull latest images**
4. Clique em **Update the stack**

## 📱 App Mobile

Portainer tem apps para iOS e Android:
- Download na App Store ou Google Play
- Acesse seus containers remotamente
- Receba notificações push (versão Pro)

## 🔗 Recursos Adicionais

- [Documentação Oficial](https://docs.portainer.io/)
- [Vídeos Tutoriais](https://www.youtube.com/c/portainerio)
- [Comunidade](https://community.portainer.io/)

---

**Última atualização**: 2026-01-09
