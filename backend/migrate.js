'use strict';
require('dotenv').config();
const { Pool } = require('pg');
const fs   = require('fs');
const path = require('path');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

// init.sql é o schema consolidado: todas as 37 tabelas base, views, funções E todos os
// dados-semente (departamentos, funcionários, atletas, pedidos, jogos, etc).
// Os outros schema_*.sql e seed_*.sql foram removidos por serem duplicados; alguns também
// estavam corrompidos (schema.sql, schema_atletas.sql).
const SQL_FILES = [
  'db/init.sql',
  'db/migration_001_auth.sql',
  'db/schema_projetos.sql',
  'db/schema_scout.sql',
  'db/schema_importacao_extrato.sql',
];

async function migrate() {
  const client = await pool.connect();
  try {
    for (const file of SQL_FILES) {
      const sql = fs.readFileSync(path.join(__dirname, file), 'utf8');
      const stmts = sql.split(';').filter(s => s.trim().length > 0);
      console.log('[MIGRATE] ' + file + ' \u2014 ' + stmts.length + ' statements');
      try {
        await client.query(sql);
      } catch (e) {
        console.log('[MIGRATE] Aviso em ' + file + ' : ' + e.message.split('\n')[0]);
      }
    }
  // Atualiza senha do admin via ADMIN_SEED_PASSWORD (nunca hardcoded)
  if (process.env.ADMIN_SEED_PASSWORD) {
    try {
      const bcrypt = require('bcrypt');
      const hash = await bcrypt.hash(process.env.ADMIN_SEED_PASSWORD, 12);
      await client.query(
        `UPDATE usuarios SET senha_hash = $1 WHERE email = $2`,
        [hash, process.env.ADMIN_EMAIL || 'ceo@riobrancosaf.com.br']
      );
      console.log('[MIGRATE] Admin password hash atualizado');
    } catch (e) {
      console.log('[MIGRATE] Admin password fix: ' + e.message.split('\n')[0]);
    }
  }
    console.log('[MIGRATE] Concluido com sucesso');
  } finally {
    client.release();
    pool.end(); // fire-and-forget: don't await to avoid hanging
  }
}

migrate().then(() => {
  process.exit(0); // explicit exit so && chain continues to node server.js
}).catch((e) => {
  console.error('[MIGRATE] Erro fatal:', e.message);
  process.exit(1);
}); 
