const { Pool } = require('pg');
require('dotenv').config();

// Pool de conexões com o PostgreSQL
// Suporta DATABASE_URL (Railway/Heroku) ou variáveis individuais
const poolConfig = process.env.DATABASE_URL
  ? {
      connectionString: process.env.DATABASE_URL,
      ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
    }
  : {
      host:     process.env.DB_HOST     || 'localhost',
      port:     parseInt(process.env.DB_PORT) || 5432,
      database: process.env.DB_NAME     || 'erp_saf',
      user:     process.env.DB_USER     || 'postgres',
      password: process.env.DB_PASSWORD || '',
    };

const pool = new Pool({
  ...poolConfig,
  max: 20,                  // máximo de conexões simultâneas
  idleTimeoutMillis: 30000, // fecha conexões ociosas após 30s
  connectionTimeoutMillis: 5000,
});

// Testa a conexão ao iniciar
pool.connect((err, client, release) => {
  if (err) {
    console.error('❌ Erro ao conectar ao PostgreSQL:', err.message);
  } else {
    console.log('✅ PostgreSQL conectado com sucesso');
    release();
  }
});

module.exports = pool;
