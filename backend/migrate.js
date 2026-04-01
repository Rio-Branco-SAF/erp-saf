// ============================================================
// migrate.js — Executa todos os SQL files na ordem correta
// Roda automaticamente antes do servidor iniciar
// ============================================================
const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');

async function migrate() {
  const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: process.env.DATABASE_URL && process.env.DATABASE_URL.includes('sslmode=disable')
      ? false
      : { rejectUnauthorized: false }
  });

  const sqlFiles = [
    'db/init.sql',
    'db/schema.sql',
    'db/schema_atletas.sql',
    'db/schema_financeiro.sql',
    'db/schema_investidores.sql',
    'db/schema_jogos.sql',
    'db/schema_metas.sql',
    'db/schema_pedidos.sql',
    'db/schema_relatorios.sql',
    'db/migration_001_auth.sql',
    'db/seed.sql',
    'db/seed_atletas.sql',
    'db/seed_financeiro.sql',
    'db/seed_investidores.sql',
    'db/seed_jogos.sql',
    'db/seed_metas.sql',
    'db/seed_pedidos.sql'
  ];

  const client = await pool.connect();
  try {
    for (const file of sqlFiles) {
      const fullPath = path.join(__dirname, file);
      if (!fs.existsSync(fullPath)) {
        console.log('[MIGRATE] Skipping (not found):', file);
        continue;
      }
      const sql = fs.readFileSync(fullPath, 'utf8');
      console.log('[MIGRATE] Running:', file);
      await client.query(sql);
    }
    console.log('[MIGRATE] Concluido com sucesso');
  } catch (err) {
    console.error('[MIGRATE] Erro:', err.message);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

migrate();
