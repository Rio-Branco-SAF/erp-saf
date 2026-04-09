require('dotenv').config();
const express    = require('express');
const cors       = require('cors');
const helmet     = require('helmet');
const morgan     = require('morgan');
const compression = require('compression');
const rateLimit  = require('express-rate-limit');

// ── Rotas ────────────────────────────────────────────────────────────────────
const authRouter        = require('./routes/auth');
const funcionariosRouter = require('./routes/funcionarios');
const usuariosRouter    = require('./routes/usuarios');
const financeiroRouter  = require('./routes/financeiro');
const pedidosRouter     = require('./routes/pedidos');
const atletasRouter     = require('./routes/atletas');
const investidoresRouter = require('./routes/investidores');
const metasRouter       = require('./routes/metas');
const relatoriosRouter  = require('./routes/relatorios');
const jogosRouter       = require('./routes/jogos');

const app  = express();
const PORT = process.env.PORT || 3001;

// ── CORS ─────────────────────────────────────────────────────────────────────
const allowedOrigins = [
  'http://localhost:3000',
  'http://localhost:5173',
  process.env.FRONTEND_URL,
].filter(Boolean);

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
    return callback(new Error('CORS: origem nao permitida'));
  },
  credentials: true,
}));

// ── Segurança ─────────────────────────────────────────────────────────────────
app.use(helmet({
  contentSecurityPolicy: false, // Frontend em domínio separado
  crossOriginResourcePolicy: { policy: 'cross-origin' },
}));

// ── Performance ───────────────────────────────────────────────────────────────
app.use(compression());

// ── Logging ───────────────────────────────────────────────────────────────────
app.use(morgan(process.env.NODE_ENV === 'production' ? 'combined' : 'dev'));

// ── Body parsers ──────────────────────────────────────────────────────────────
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// ── Rate limiting ─────────────────────────────────────────────────────────────
const globalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutos
  max: 500,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Muitas requisições. Tente novamente em 15 minutos.' },
});

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20, // Mais restrito para login
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Muitas tentativas de login. Tente novamente em 15 minutos.' },
});

app.use('/api/', globalLimiter);
app.use('/api/auth/', authLimiter);

// ── Health check ──────────────────────────────────────────────────────────────
app.get('/api/health', (_req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    env: process.env.NODE_ENV || 'development',
    version: require('./package.json').version,
  });
});

// ── Rotas da API ──────────────────────────────────────────────────────────────
app.use('/api/auth',         authRouter);
app.use('/api/funcionarios', funcionariosRouter);
app.use('/api/usuarios',     usuariosRouter);
app.use('/api/financeiro',   financeiroRouter);
app.use('/api/pedidos',      pedidosRouter);
app.use('/api/atletas',      atletasRouter);
app.use('/api/investidores', investidoresRouter);
app.use('/api/metas',        metasRouter);
app.use('/api/relatorios',   relatoriosRouter);
app.use('/api/jogos',        jogosRouter);

// ── 404 ───────────────────────────────────────────────────────────────────────
app.use((_req, res) => {
  res.status(404).json({ error: 'Rota não encontrada.' });
});

// ── Error handler global ──────────────────────────────────────────────────────
// eslint-disable-next-line no-unused-vars
app.use((err, _req, res, _next) => {
  const status = err.status || err.statusCode || 500;
  if (process.env.NODE_ENV !== 'production') console.error(err);
  res.status(status).json({
    error: err.message || 'Erro interno do servidor.',
    ...(process.env.NODE_ENV !== 'production' && { stack: err.stack }),
  });
});

// ── Start ─────────────────────────────────────────────────────────────────────
const server = app.listen(PORT, () => {
  console.log(`[ERP-SAF] Servidor rodando na porta ${PORT} (${process.env.NODE_ENV || 'development'})`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('[ERP-SAF] SIGTERM recebido — encerrando servidor...');
  server.close(() => {
    console.log('[ERP-SAF] Servidor encerrado.');
    process.exit(0);
  });
});

module.exports = app;
