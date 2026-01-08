# Política de Segurança

## 🔒 Práticas de Segurança Recomendadas

### Credenciais e Senhas

1. **NUNCA** commite o arquivo `.env` no Git
2. Use senhas fortes com no mínimo:
   - 16 caracteres
   - Letras maiúsculas e minúsculas
   - Números e caracteres especiais
3. Troque TODAS as senhas padrão em produção
4. Use geradores de senha seguros

### Tokens e API Keys

- Mantenha o `CLOUDFLARE_TUNNEL_TOKEN` em segredo
- Gere uma `EVOLUTION_API_KEY` única e complexa
- Rotacione tokens periodicamente (recomendado: a cada 90 dias)
- Nunca compartilhe tokens em:
  - Repositórios públicos
  - Logs
  - Screenshots
  - Mensagens de chat

### Docker e Containers

1. Mantenha as imagens Docker atualizadas:
   ```bash
   docker-compose pull
   docker-compose up -d
   ```

2. Use networks isoladas (já configurado no docker-compose.yml)

3. Limite o acesso às portas:
   - Exponha apenas as portas necessárias
   - Use firewall para restringir acesso
   - Considere usar VPN para acesso remoto

### Banco de Dados

1. **PostgreSQL**:
   - Use senha forte para o usuário `POSTGRES_PASSWORD`
   - Não exponha a porta 5432 externamente
   - Faça backups regulares
   - Mantenha backups criptografados

2. **Redis**:
   - Configure senha se habilitar Redis
   - Não exponha a porta 6379 externamente

### N8N

1. **Autenticação**:
   - Sempre mantenha `N8N_BASIC_AUTH_ACTIVE=true`
   - Use senha forte para `N8N_BASIC_AUTH_PASSWORD`
   - Considere usar autenticação de dois fatores em produção

2. **Workflows**:
   - Revise workflows antes de ativar
   - Não armazene credenciais em workflows
   - Use as credenciais do N8N adequadamente

### Evolution API

1. Use API Key forte e única
2. Configure webhooks apenas para URLs confiáveis
3. Monitore logs regularmente
4. Limite rate limiting se possível

## 🚨 Reportando Vulnerabilidades

Se você descobrir uma vulnerabilidade de segurança, por favor:

1. **NÃO** abra uma issue pública
2. Envie um email para: [seu-email@dominio.com]
3. Inclua:
   - Descrição detalhada da vulnerabilidade
   - Passos para reproduzir
   - Impacto potencial
   - Sugestões de correção (se houver)

## 📋 Checklist de Segurança

Antes de ir para produção, verifique:

- [ ] Arquivo `.env` não está no Git
- [ ] Todas as senhas foram alteradas dos valores padrão
- [ ] Senhas são fortes (16+ caracteres)
- [ ] Tokens do Cloudflare estão seguros
- [ ] N8N tem autenticação habilitada
- [ ] PostgreSQL não está exposto externamente
- [ ] Redis não está exposto externamente (se usado)
- [ ] Firewall configurado corretamente
- [ ] Backups configurados e testados
- [ ] Logs sendo monitorados
- [ ] SSL/TLS habilitado (em produção)
- [ ] Updates de segurança aplicados

## 🔄 Manutenção de Segurança

### Diariamente
- Monitore logs de acesso
- Verifique tentativas de autenticação falhadas

### Semanalmente
- Revise workflows ativos no N8N
- Verifique uso de recursos (CPU, memória, disco)

### Mensalmente
- Atualize imagens Docker
- Revise permissões de acesso
- Verifique integridade dos backups

### Trimestralmente
- Rotacione tokens e API keys
- Audite senhas
- Revise política de segurança
- Teste restauração de backups

## 🛡️ Boas Práticas Adicionais

### Ambiente de Produção

1. **Use HTTPS**:
   - Configure SSL/TLS
   - Use Cloudflare ou Nginx como proxy reverso
   - Force redirecionamento HTTP → HTTPS

2. **Isolamento**:
   - Use servidor dedicado ou VPS
   - Isole do ambiente de desenvolvimento
   - Mantenha ambientes separados

3. **Monitoramento**:
   - Configure alertas para erros
   - Monitore uso de recursos
   - Registre todas as atividades

4. **Backups**:
   ```bash
   # Exemplo de backup do PostgreSQL
   docker exec postgres pg_dump -U root evolution > backup_$(date +%Y%m%d).sql

   # Criptografe o backup
   gpg -c backup_$(date +%Y%m%d).sql
   ```

### Limitações de Acesso

```yaml
# Exemplo: Adicione no docker-compose.yml para limitar acesso
evolution-api:
  # ...
  environment:
    - RATE_LIMIT_ENABLED=true
    - RATE_LIMIT_MAX=100
```

## 📞 Contato

Para questões de segurança: [seu-email@dominio.com]

---

**Última atualização**: 2026-01-08
