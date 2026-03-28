# 🚀 Guia de Deploy — ERP SAF

## Visão Geral

| Parte | Plataforma | Custo | Link |
|-------|-----------|-------|------|
| Backend (API) | Railway | Gratuito até $5/mês de uso | railway.app |
| Banco de Dados | Railway (PostgreSQL) | Gratuito até 1 GB | railway.app |
| Frontend | Netlify | Gratuito | netlify.com |

---

## PASSO 1 — Subir o código no GitHub

1. Acesse **github.com** e crie um repositório novo (ex: `erp-saf`)
2. No seu computador, dentro da pasta `erp-saf`, execute:

```bash
git init
git add .
git commit -m "ERP SAF — versão inicial completa"
git branch -M main
git remote add origin https://github.com/SEU-USUARIO/erp-saf.git
git push -u origin main
```

> ⚠️ Certifique-se que existe um arquivo `.gitignore` ignorando `node_modules/` e `.env`

---

## PASSO 2 — Deploy do Backend no Railway

### 2.1 Criar conta e projeto

1. Acesse **railway.app** e clique em **"Start a New Project"**
2. Escolha **"Deploy from GitHub repo"**
3. Autorize o Railway a acessar seu GitHub
4. Selecione o repositório `erp-saf`

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

Após o deploy (~2 min), acesse a URL gerada pelo Railway com `/api/health`:
```
https://erp-saf-production.up.railway.app/api/health
```
Deve retornar: `{"status":"ok", ...}`

---

## PASSO 3 — Inicializar o Banco de Dados

Com o banco criado, execute o script SQL completo para criar as tabelas e popular com dados:

### Opção A — Via Railway Dashboard (mais fácil)

1. No painel do Railway, clique no serviço **PostgreSQL**
2. Vá em **"Data"** → clique em **"Query"**
3. Cole o conteúdo do arquivo `backend/db/init.sql` e execute

### Opção B — Via terminal (psql)

```bash
# Instale o psql se não tiver: https://www.postgresql.org/download/
psql "postgresql://USUARIO:SENHA@HOST:PORT/BANCO" -f backend/db/init.sql
```
> A string de conexão completa fica em: Railway ₒ PostgreSQL ₒ Variables → DATABASE_URL

---

## PASSO 4 — Deploy do Frontend no Netlify

### 4.1 Criar conta e conectar GitHub

1. Acesse **netlify.com** e clique em **"Add new site"**
2. Escolha **"Import an existing project"**
3. Selecione **"Deploy with GitHub"**
4. Autorize o Netlify e selecione o repositório `erp-saf`

### 4.2 Configurar o build

| Campo | Valor |
|-------|-------|
| Branch | `main` |
| Base directory | *(vazio)* |
| Build command | *(vazio)* |
| Publish directory | `frontend` |

> O arquivo `netlify.toml` na raiz do projeto já configura isso automaticamente.

### 4.3 Publicar

Clique em **"Deploy site"**. O Netlify vai gerar uma URL como:
```
https://magical-sundae-abc123.netlify.app
```

---

## PASSO 5 — Conectar Frontend ↔ Backend

### 5.1 Atualizar a URL da API no frontend

Edite o arquivo `frontend/config.js`:

```js
window.ERP_CONFIG = {
  API_URL: "https://SEU-BACKEND.up.railway.app",  // ← URL do Railway
  NOME_SAF: "Nome do Seu Clube",
  VERSAO: "1.0.0",
};
```

### 5.2 Atualizar o CORS no Railway

No Railway, adicione/atualize a variável:
```
FRONTEND_URL = https://seu-site.netlify.app
```

### 5.3 Fazer push das mudanças

```bash
git add frontend/config.js
git commit -m "config: conecta frontend ao backend em produção"
git push
```

O Netlify e o Railway vão rede