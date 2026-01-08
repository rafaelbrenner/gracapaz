# 📤 Como Publicar no GitHub

Este guia mostra como publicar seu projeto com segurança no GitHub.

## ✅ Verificação de Segurança Pré-Publicação

### 1. Verifique se o .env está protegido

```bash
# Este comando deve retornar ".env"
git check-ignore .env

# Este comando NÃO deve mostrar .env
git status
```

✅ **IMPORTANTE**: Se `.env` aparecer em `git status`, **NÃO CONTINUE**. Verifique seu `.gitignore`.

### 2. Procure por credenciais nos arquivos

```bash
# Procure por tokens e senhas nos arquivos que serão commitados
git diff --cached | grep -i "password\|token\|secret\|key"
```

Se aparecer algo suspeito, **NÃO FAÇA O COMMIT** ainda.

### 3. Revise os arquivos que serão enviados

```bash
git status
```

Devem aparecer apenas:
- ✅ `.env.example`
- ✅ `.gitignore`
- ✅ `docker-compose.yml`
- ✅ `README.md`
- ✅ `SECURITY.md`
- ✅ `DEPLOY.md`
- ✅ `LICENSE`

**NÃO** devem aparecer:
- ❌ `.env`
- ❌ Arquivos de volume Docker
- ❌ Logs

## 🚀 Publicando no GitHub

### Opção 1: Criar Repositório via GitHub Web

1. **Acesse** [github.com/new](https://github.com/new)

2. **Configure o repositório**:
   - Nome: `graca_paz` (ou outro nome)
   - Descrição: "Sistema de automação WhatsApp para Igreja com Evolution API e N8N"
   - Visibilidade:
     - ✅ **Public** (se quiser compartilhar)
     - ✅ **Private** (se quiser manter privado)
   - **NÃO** marque "Initialize with README" (já temos um)

3. **Copie a URL do repositório**
   - Exemplo: `https://github.com/seu-usuario/graca_paz.git`

4. **No seu terminal**:

```bash
cd "c:\Users\rafae\OneDrive\Documentos\graca_paz"

# Configure o Git (se ainda não fez)
git config --global user.name "Seu Nome"
git config --global user.email "seu-email@exemplo.com"

# Faça o commit inicial
git add -A
git commit -m "Initial commit: Sistema de automação WhatsApp

- Configuração Docker Compose com Evolution API, N8N, PostgreSQL e Redis
- Documentação completa de setup e segurança
- Exemplo de variáveis de ambiente
- Proteção de credenciais via .gitignore"

# Adicione o repositório remoto (use a URL que você copiou)
git remote add origin https://github.com/seu-usuario/graca_paz.git

# Envie para o GitHub
git branch -M main
git push -u origin main
```

### Opção 2: Criar Repositório via GitHub CLI

```bash
# Instale GitHub CLI se ainda não tem
# Download: https://cli.github.com/

# Login
gh auth login

# Crie o repositório (público)
gh repo create graca_paz --public --source=. --remote=origin --push

# Ou privado
gh repo create graca_paz --private --source=. --remote=origin --push
```

## 🔍 Verificação Pós-Publicação

Após publicar, **VERIFIQUE IMEDIATAMENTE**:

1. **Acesse seu repositório no GitHub**
   - URL: `https://github.com/seu-usuario/graca_paz`

2. **Verifique se o .env NÃO está lá**
   - ❌ Se estiver, **DELETE O REPOSITÓRIO IMEDIATAMENTE** e comece de novo
   - ✅ Deve aparecer apenas `.env.example`

3. **Procure por credenciais**
   - Use a busca do GitHub
   - Procure por suas senhas reais
   - Se encontrar algo, **DELETE O REPOSITÓRIO**

4. **Verifique o .gitignore**
   - Deve estar presente
   - Deve conter `.env` na lista

## 🚨 O que fazer se você commitou credenciais

### Se ainda NÃO fez push:

```bash
# Desfaça o último commit
git reset --soft HEAD~1

# Remova o arquivo problemático
git reset HEAD .env

# Verifique o .gitignore
cat .gitignore

# Faça o commit novamente
git add -A
git commit -m "Initial commit"
```

### Se já fez push:

1. **DELETE o repositório no GitHub imediatamente**
   - Settings → Danger Zone → Delete this repository

2. **Troque TODAS as credenciais comprometidas**:
   - Senha do PostgreSQL
   - API Key do Evolution
   - Senha do N8N
   - Token do Cloudflare

3. **Limpe o histórico do Git local**:
   ```bash
   rm -rf .git
   git init
   ```

4. **Comece de novo** seguindo este guia

5. **Revogue tokens** comprometidos:
   - Cloudflare: Crie um novo túnel
   - API Keys: Gere novas chaves

## 📝 Atualizações Futuras

Para atualizar o repositório:

```bash
# Faça suas alterações
# ...

# Verifique o que mudou
git status
git diff

# Adicione as mudanças
git add .

# Faça o commit
git commit -m "Descrição clara das mudanças"

# Envie para o GitHub
git push
```

## 🔐 Boas Práticas

### Sempre antes de commitar:

```bash
# 1. Verifique o status
git status

# 2. Veja as diferenças
git diff

# 3. Verifique se .env não está incluído
git ls-files | grep .env

# 4. Se .env aparecer, PARE e remova:
git rm --cached .env
```

### Use Git Hooks (Opcional)

Crie um hook para prevenir commits acidentais de .env:

```bash
# Crie o arquivo
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
if git diff --cached --name-only | grep -q "^\.env$"; then
    echo "❌ ERRO: Tentativa de commitar .env bloqueada!"
    echo "O arquivo .env contém credenciais sensíveis."
    exit 1
fi
EOF

# Torne executável
chmod +x .git/hooks/pre-commit
```

## 📊 Checklist Final

Antes de publicar, confirme:

- [ ] Arquivo `.env` está no `.gitignore`
- [ ] Executei `git check-ignore .env` e retornou ".env"
- [ ] `git status` NÃO mostra `.env`
- [ ] Revisei TODOS os arquivos em `git status`
- [ ] `.env.example` não contém credenciais reais
- [ ] `docker-compose.yml` usa variáveis de ambiente
- [ ] README.md está completo
- [ ] SECURITY.md foi revisado
- [ ] Testei localmente antes de publicar

## 🎉 Pronto!

Se tudo estiver ✅, seu código está seguro para ser publicado!

## 📞 Ajuda

Se tiver dúvidas:
1. Releia este guia
2. Verifique [SECURITY.md](SECURITY.md)
3. Consulte a [documentação do Git](https://git-scm.com/doc)

---

**⚠️ LEMBRE-SE**: É melhor ser paranóico com segurança do que se arrepender depois!
