# ERP SAF — Sistema de Gestão

## Módulo 1: Funcionários e Comissão Técnica

### Pré-requisitos
- Node.js 18+
- PostgreSQL 14+

### Como rodar

#### 1. Banco de dados
```bash
psql -U postgres
CREATE DATABASE erp_saf;
\c erp_saf
\i backend/db/schema.sql
\i backend/db/seed.sql   # dados de exemplo
```

#### 2. Backend
```bash
cd backend
cp .env.example .env     # preencha com suas credenciais
npm install
npm run dev              # http://localhost:3001
```

#### 3. Frontend
Abra o arquivo `frontend/index.html` no navegador.
Em produção, suba com qualquer servidor estático (Nginx, Vercel etc.)

### Endpoints da API
| Método | Rota | Descrição |
|--------|------|-----------|
| POST | /api/auth/login | Login |
| GET | /api/auth/me | Usuário logado |
| GET | /api/funcionarios | Listar com filtros |
| GET | /api/funcionarios/resumo | Totais para dashboard |
| GET | /api/funcionarios/:id | Detalhe completo |
| POST | /api/funcionarios | Criar |
| PUT | /api/funcionarios/:id | Editar |
| PATCH | /api/funcionarios/:id/status | Alterar status |
| GET | /api/funcionarios/aux/departamentos | Departamentos |
