'use strict';
require('dotenv').config();
const { Pool } = require('pg');
const fs   = require('fs');
const path = require('path');

const pool = new Pool({ connectionString: process.env.DATABASE_URL });

const SQL_FILES = [
  'db/init.sql',
  'db/schema_pedidos.sql',
  'db/schema_relatorios.sql',
  'db/schema_atletas.sql',
  'db/schema_financeiro.sql',
  'db/schema.sql',
  'db/migration_001_auth.sql',
  'db/seed.sql',
  'db/seed_atletas.sql',
  'db/seed_financeiro.sql',
  'db/seed_investidores.sql',
  'db/seed_jogos.sql',
  'db/seed_metas.sql',
  'db/seed_pedidos.sql',
];

async function migrate() {
  const client = await pool.connect();
  try {
    for (const file of SQL_FILES) {
      const sql = fs.readFileSync(path.join(__dirname, file), 'utf8');
      const stmts = sql.split(';').filter(s => s.trim().length > 0);
      console.log('[MIGRATE] ' + file + ' — ' + stmts.length + ' statements');
      try {
        await client.query(sql);
      } catch (e) {
        console.log('[MIGRATE] Aviso em ' + file + ' : ' + e.message.split('
')[0]);
      }
    }
    console.log('[MIGRATE] Concluido com sucesso');
  } finally {
    client.release();
    await pool.end();
  }
}

migrate().catch((e) => {
  console.error('[MIGRATE] Erro fatal:', e.message);
  process.exit(1);
});
