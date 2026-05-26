'use strict';
require('dotenv').config();
const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

const args = process.argv.slice(2);
const COMMIT = args.includes('--commit');
const FILES = args.filter(a => a !== '--commit');
if (FILES.length === 0) {
  console.error('Uso: node diagnose.js [--commit] db/init.sql [db/outro.sql ...]');
  process.exit(2);
}

function ctx(sql, pos, radius = 120) {
  const start = Math.max(0, pos - radius);
  const end = Math.min(sql.length, pos + radius);
  const before = sql.slice(start, pos);
  const at = sql.slice(pos, pos + 1);
  const after = sql.slice(pos + 1, end);
  return { before, at, after, lineNum: sql.slice(0, pos).split('\n').length };
}

(async () => {
  const client = await pool.connect();
  let allOk = true;
  try {
    for (const file of FILES) {
      const sql = fs.readFileSync(path.join(__dirname, file), 'utf8');
      process.stdout.write(`\n=== ${file} (${sql.length} bytes) ===\n`);
      try {
        await client.query('BEGIN');
        await client.query(sql);
        if (COMMIT) {
          await client.query('COMMIT');
          console.log('OK (COMMITTED)');
        } else {
          await client.query('ROLLBACK');
          console.log('OK (rolled back)');
        }
      } catch (e) {
        await client.query('ROLLBACK').catch(() => {});
        allOk = false;
        const pos = e.position ? parseInt(e.position, 10) - 1 : null;
        console.log(`ERRO: ${e.message}`);
        console.log(`  code=${e.code} position=${e.position} line=${pos !== null ? ctx(sql, pos).lineNum : '?'}`);
        if (pos !== null) {
          const c = ctx(sql, pos);
          console.log('  --- 120 chars antes ---');
          console.log(c.before);
          console.log(`  >>>>>> caractere @ pos ${pos}: ${JSON.stringify(c.at)} <<<<<<`);
          console.log('  --- 120 chars depois ---');
          console.log(c.after);
        }
      }
    }
  } finally {
    client.release();
    pool.end();
  }
  process.exit(allOk ? 0 : 1);
})();
