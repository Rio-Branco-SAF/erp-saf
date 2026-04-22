require('dotenv').config();
const express = require('express');
const helmet  = require('helmet');
const rateLimit = require('express-rate-limit');
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
const extratoRoutes      = require('./routes/extrato');
const projetosRoutes     = require('./routes/projetos');
const scoutRoutes        = require('./routes/scout');
const prospeccaoRoutes   = require('./routes/prospeccao');


const app  = express();
const PORT = process.env.PORT || 3001;

// ============================================================
// Middlewares globais
// ============================================================
app.use(cors({
  origin: (origin, callback) => {
    const allowed = [
      process.env.FRONTEND_URL,
      'https://erp-saf.vercel.app',
      'https://erp-saf-git-main-rio-branco-saf.vercel.app',
      'http://localhost:5173',
      'http://localhost:3000',
      'http://localhost:3001',
    ].filter(Boolean);
    if (!origin || allowed.includes(origin)) return callback(null, true);
    return callback(new Error('CORS: origem não permitida → ' + origin));
  },
  credentials: true,
}));
app.use(helmet());
app.use(express.json({ limit: '1mb' }));
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
// Rate limit: máx 20 tentativas de login por 15 min por IP
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: { erro: 'Muitas tentativas. Tente novamente em 15 minutos.' },
});
app.use('/api/auth/login', loginLimiter);
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
app.use('/api/extrato',      extratoRoutes);
app.use('/api/projetos',     projetosRoutes);
app.use('/api/scout',        scoutRoutes);
app.use('/api/prospeccao',  prospeccaoRoutes);
const seedDemoRoutes = require('./routes/seed_demo');
app.use('/api/seed-demo',    seedDemoRoutes);

// Health check
app.get('/api/health', (_req, res) => {
  res.json({
    status: 'ok',
    versao: '1.0.0',
    modulos: ['funcionarios', 'financeiro', 'pedidos', 'atletas', 'investidores', 'metas', 'relatorios', 'jogos', 'prospeccao', 'projetos', 'scout'],
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
