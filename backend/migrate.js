// ============================================================
// migrate.js — Executa todos os SQL files com splitter robusto
// Suporta DO $$ ... $$ e PL/pgSQL
// ============================================================
const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');

// Split SQL preservando dollar-quoted blocks (DO $$...$$)
function splitStatements(sql) {
  const stmts = [];
  let cur = '';
  let inDQ = false;
  let dqTag = '';
  let i = 0;
  while (i < sql.length) {
    if (!inDQ && sql[i] === '$') {
      const end = sql.indexOf('$', i + 1);
      if (end !== -1) {
        const tag = sql.substring(i, end + 1);
        if (/^\$[A-Za-z0-9_]*\$$/.test(tag)) {
          inDQ = true; dqTag = tag; cur += tag; i = end + 1; continue;
        }
      }
    }
    if (inDQ && sql.startsWith(dqTag, i)) {
      inDQ = false; cur += dqTag; i += dqTag.length; continue;
    }
    if (!inDQ && sql[i] === '-' && sql[i+1] === '-') {
      const nl = sql.indexOf('\n', i);
      const end2 = nl === -1 ? sql.length : nl;
      cur += sql.substring(i, end2); i = end2; continue;
    }
    if (!inDQ && sql[i] === ';') {
      cur += ';';
      const s = cur.trim();
      if (s && s !== ';') stmts.push(s);
      cur = ''; i++; continue;
    }
    cur += sql[i]; i++;
  }
  const rem = cur.trim();
  if (rem && rem !== ';') stmts.push(rem);
  return stmts;
}

async function migrate() {
  const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: false
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
      if (!fs.existsSync(fullPath)) { console.log('[MIGRATE] Skip:', file); continue; }
      const sql = fs.readFileSync(fullPath, 'utf8');
      const stmts = splitStatements(sql);
      console.log('[MIGRATE]', file, '—', stmts.length, 'statements');
      for (const stmt of stmts) {
        try {
          await client.query(stmt);
        } catch (e) {
          if (e.message.includes('already exists') || e.message.includes('duplicate')) {
            // ignore safe duplicates
          } else {
            console.warn('[MIGRATE] Aviso em', file, ':', e.message.substring(0, 120));
          }
        }
      }
    }
    console.log('[MIGRATE] Concluido com sucesso');
  } finally {
    client.release();
    await pool.end();
  }
}

migrate().catch(err => { console.error('[MIGRATE] Fatal:', err.message); process.exit(1); });

process.exit(0);
process.exit(0);
