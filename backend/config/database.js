const { Pool } = require('pg');

// ── Conexão com o banco ───────────────────────────────────────────────────────
// Railway fornece DATABASE_URL automaticamente.
// Em desenvolvimento, usa variáveis individuais do .env.

let pool;

if (process.env.DATABASE_URL) {
  // Produção (Railway) - URL única
  pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: process.env.NODE_ENV === 'production'
      ? { rejectUnauthorized: false }
      : false,
    max: 10,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 5000,
  });
} else {
  // Desenvolvimento local - variáveis individuais
  pool = new Pool({
    host:     process.env.DB_HOST     || 'localhost',
    port:     parseInt(process.env.DB_PORT || '5432'),
    database: process.env.DB_NAME     || 'erp_saf',
    user:     process.env.DB_USER     || 'postgres',
    password: process.env.DB_PASSWORD || '',
    max: 10,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 5000,
  });
}

// Testar conexão ao iniciar
pool.connect((err, client, release) => {
  if (err) {
    console.error('[DB] Erro ao conectar ao PostgreSQL:', err.message);
    return;
  }
  client.query('SELECT NOW()', (err2, result) => {
    release();
    if (err2) {
      console.error('[DB] Erro no teste de conexão:', err2.message);
    } else {
      console.log('[DB] PostgreSQL conectado —', result.rows[0].now);
    }
  });
});

// Log de erros inesperados no pool
pool.on('error', (err) => {
  console.error('[DB] Erro inesperado no pool:', err.message);
});

module.exports = pool;
