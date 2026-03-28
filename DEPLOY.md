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
4. Selecione o repositório `erp-