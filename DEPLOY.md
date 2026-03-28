# ðŸš€ Guia de Deploy â€” ERP SAF

## VisÃ£o Geral

| Parte | Plataforma | Custo | Link |
|-------|-----------|-------|------|
| Backend (API) | Railway | Gratuito atÃ© $5/m7Ãªn de uso | railway.app |
| Banco de Dados | Railway (PostgreSQL) | Gratuito atÃ© 1 GB | railway.app |
| Frontend | Netlify | Gratuito | netlify.com |

---

## PASSO 1 â€– Subir o cÃ³diÏo no GitHub

1. Acesse **github.com** e cril um repositÃ³rio novo (ex:"€ `erp-saf`)
2. No seu computador, dentro da pasta `erp-saf`, execute:

```bash
git init
git add .
git commit -m "ERP SAF â€” versÃ£o inicial completa"
git branch -M main
git remote add origin https://github.com/SEU-USUARIO/erp-saf.git
git push -u origin main
```

> âš ï¸ Certifique-se que existe um arquivo `.gitignore` ignorando `node_modules/` e a.env`

---

## PASSO 2 â€” Deploy do Backend no Railway

### 2.1 Criar conta e projeto

1. Acesse **railway.app** e clique em **"Start a New Project"**
2. Escolha **"Deploy from GitHub repo"**
3. Autorize o Railway a acessar seu GitHub
4. Selecione o repositÃ³rio `erp-saf`

### 2.2 Adicionar PostgreSQL

1. No painel do projeto, clique em **"+ New"**
2. Selecione **"Database" → "Add PostgreSQL"**
3. O Railway criará o banco automaticamente

### 2.3 Configurar variáveis de ambiente

No painel do serviço backend, clique em **"Variables"** e adicione:

```
DATABASE_URL     = (copie o valor da variável DATABASE_URL do serviço PostgreSQL)
JWT_SECRET       = (gere uma chave: node -e "console.log(require('crypto').randomBytes(64).toString('hex'))")
JWT_EXPIRES_IN   = 8h
NODE_ENV         = production
FRONTEND_URL     = https://SEU-SITE.netlify.app   ← preencher depois do Passo 3
```

> 💡 O `DATABASE_URL` do PostgreSQL fica em:
> Serviço PostgreSQL → Variables → DATABASE_URL

### 2.4 Configurar o build

O arquivo `railway.toml` já está configurado. O Railway deve detectar automaticamente.

Se necessário, em **Settings → Build**:
- Build Command: `cd backend && npm install --omit=dev`
- Start Command: `cd backend && node server.js`

### 2.5 Verificar o deploy

Após o deploy (~2 min), ac