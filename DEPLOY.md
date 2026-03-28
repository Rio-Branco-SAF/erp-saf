saf`

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

Após o deploy (~2 min), acsaf`

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
3. Cole o conteudo do arquivo `backend/db/init.sql` e execute

### Op��ão B — Via terminal (psql)

```bash
# Instale o psql se não tiver: https://www.postgresql.org/download/
psql "postgresql://USUARIO:SENHA:HOST:PORT/BANCO" -f backend/db/init.sql
```
> A string de conezão completa fica em: Railway → PostgreSQL → Variables → DATABASE_URL

---

## PASSO 4 — Deploy do Frontend no Netlify

### 4.1 Criar conta e conectar GitHub

1. Acesse **netlify.com** e clique em **"Add new site"**
2. Escolha **"Import an existing project"**
3. Selecione **"Deploy with GitHub"**
4. Autorize o Netlify e selecione o repositório `erp-saf`

### 4.2 Configurar o build

| Campo | Valor |
|--------|-------|
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
  API_URL: "https://SEU-BACMERSQNCS://SEU-BACMERSQN-
`window.ERP_CONFIG = {
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

O Netlify e o Railway vão redeployar automaticamente em ~1 minuto.

---

## PASSO 6 — Testar o sistema

Accesse o frontend no Netlify e faça login com as credenciais padrão:

| Usuário | Senha | Perfil |
|---------|--------|--------|
| `admin@erpsaf.com` | `admin123` | Administrador |
| `gestor@erpsaf.com` | `gestor123` | Gestor |
| `financeiro@erpsaf.com` | `fin123` | Financeiro |

> ⚠️ **Importante:** Troque as senhas imediatamente após o primeiro login!

---

## Domínio Personalizado (opcional)

### No Netlify:
1. Site Settings → Domain management → Add custom domain
2. Aponte seu DNS para os servidores do Netlify

### No Railway:
1. Settings → Networking → Add custom domain
2. Configure o CNAME no seu provedor DNS

---

## Checklist Final

- [ ] Código no GitHub
- [ ] Backend rodando no Railway (`/api/health` responde OK)
- [ ] PostgreSQL criado e `init.sql` executado
- [ ] Variáveis de ambiente no Railway configuradas
- [ ] Frontend no Netlify publicado
- [ ] `frontend/config.js` com a URL do Railway
- [ ] `FRONTEND_URL` no Railway com a URL do Netlify
- [ ] Login testado com success
- [ ] Senhas padrão trocadas

---

## Problemas Comuns

### Backend não inicia
- Verifique se `DATABASE_URL` está configurado no Railway
- Verifique os logs em: Railway → serviço → Deployments → View logs

### Erro de CORS no navegador
- Confirme que `FRONTEND_URL` no Railway é exatamente a URL do Netlify (sem `/` no final)

### Frontend não carrega dados
- Verifique `frontend/config.js` — a `API_URL` precisa ser a URL pública do Railway
- Teste direto: `https://SEU-BACKEND.up.railway.app/api/health`

### Banco sem dados
- Execute novamente o `init.sql` via Railway Data → Query

---

## Arquivos de Configuração

| Arquivo | Finalidade |
|---------|-----------|
| `railway.toml` | Instrui o Railway como buildar e startar o backend |
| `netlify.toml` | Instrui o Netlify qual pasta publicar e rotas |
| `backend/.env.example` | Template das variáveis de ambiente |
| `backend/db/init.sql` | Script SQL completo (schema + seeds) |
| `frontend/config.js` | URL da API usada pelo f