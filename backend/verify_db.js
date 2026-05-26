'use strict';
require('dotenv').config();
const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

(async () => {
  const c = await pool.connect();
  try {
    const tables = await c.query(
      `SELECT tablename FROM pg_tables WHERE schemaname='public' ORDER BY tablename`
    );
    console.log(`TABELAS (${tables.rows.length}):`);
    console.log(tables.rows.map(r => '  ' + r.tablename).join('\n'));

    const counts = ['departamentos','funcionarios','usuarios','atletas',
      'contratos_atleta','pedidos_compra','jogos','lancamentos_financeiros',
      'investidores','metas','projetos','jogadores_scout','refresh_tokens'];
    console.log('\nCONTAGENS:');
    for (const t of counts) {
      try {
        const r = await c.query(`SELECT COUNT(*)::int AS n FROM ${t}`);
        console.log(`  ${t.padEnd(28)} ${r.rows[0].n}`);
      } catch (e) {
        console.log(`  ${t.padEnd(28)} ERRO: ${e.message}`);
      }
    }

    const admin = await c.query(
      `SELECT id, email, nome, perfil FROM usuarios WHERE perfil='admin'`
    );
    console.log('\nADMIN(S):');
    admin.rows.forEach(r => console.log(' ', r));
  } finally {
    c.release();
    pool.end();
  }
})().catch(e => { console.error(e); process.exit(1); });
