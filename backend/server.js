require('dotenv').config();
const express = require('express');
const cors    = require('cors');

const authRoutes         = require('./routes/auth');
const funcionariosRoutes = require('./routes/funcionarios');
const usuariosRoutes     = require('./routes/usuarios');
const financeiroRoutes   = require('./routes/financeiro');
const pedidosRoutes      = require('./routes/pedidos');
const atletasRoutes      = require('./routes/atletas');
const investidoresRoutes = require('./routes/investidores');
const metasRoutes        = require('./routes/metas');
const relatoriosRoutes   = require('./routes/relatorios');
const jogosRoutes        = require('./routes/jogos');

const app  = express();
const PORT = process.env.PORT || 3001;

// ============================================================
// Middlewares globais
// ============================================================
app.use(cors({
  origin:      process.env.FRONTEND_URL || 'http://localhost:5173',
  credentials: true,
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Log de requisições em desenvolvimento
if (process.env.NODE_ENV !== 'production') {
  app.use((req, _res, next) => {
    console.log(`[${new Date().toISOString()}] ${req.method} ${req.path}`);
    next();
  });
}

// ============================================================
// Rotas
// ============================================================
app.use('/api/auth',         authRoutes);
app.use('/api/funcionarios', funcionariosRoutes);
app.use('/api/usuarios',     usuariosRoutes);
app.use('/api/financeiro',   financeiroRoutes);
app.use('/api/pedidos',      pedidosRoutes);
app.use('/api/atletas',      atletasRoutes);
app.use('/api/investidores', investidoresRoutes);
app.use('/api/metas',        metasRoutes);
app.use('/api/relatorios',   relatoriosRoutes);
app.use('/api/jogos',        jogosRoutes);

// Health check
app.get('/api/health', (_req, res) => {
  res.json({
    status: 'ok',
    versao: '1.0.0',
    modulos: ['funcionarios', 'financeiro', 'pedidos', 'atletas', 'investidores', 'metas', 'relatorios', 'jogos'],
    timestamp: new Date().toISOString(),
  });
});

// Rota não encontrada
app.use((_req, res) => {
  res.status(404).json({ erro: 'Rota não encontrada.' });
});

// Handler de erros global
app.use((err, _req, res, _next) => {
  console.error('Erro não tratado:', err);
  res.status(500).json({ erro: 'Erro interno do servidor.' });
});

// ============================================================
// Inicia o servidor
// ============================================================
app.listen(PORT, () => {
  console.log(`\n🚀 ERP SAF — Backend rodando em http://localhost:${PORT}`);
  console.log(`📋 Ambiente: ${process.env.NODE_ENV || 'development'}`);
  console.log(`🔗 Endpoints disponíveis:`);
  console.log(`   POST   /api/auth/login`);
  console.log(`   GET    /api/auth/me`);
  console.log(`   GET    /api/funcionarios`);
  console.log(`   GET    /api/funcionarios/resumo`);
  console.log(`   GET    /api/funcionarios/:id`);
  console.log(`   POST   /api/funcionarios`);
  console.log(`   PUT    /api/funcionarios/:id`);
  console.log(`   PATCH  /api/funcionarios/:id/status`);
  console.log(`   GET    /api/funcionarios/aux/departamentos\n`);
});
