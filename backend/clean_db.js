'use strict';
// Limpa todos os dados de todas as tabelas EXCETO o usuario admin.
// Resetta os sequences (IDs voltam pra 1).
// Use UMA VEZ ao migrar da base demo pra dados reais.
require('dotenv').config({ path: require('path').join(__dirname, '.env') });
const { Pool } = require('pg');
const bcrypt = require('bcrypt');

const ADMIN_EMAIL = 'ceo@saf.com.br';
const ADMIN_PASSWORD = process.env.ADMIN_RESET_PASSWORD || 'TempCheck@2026';
const ADMIN_NOME = 'Administrador';

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

(async () => {
  const client = await pool.connect();
  try {
    console.log('1. Listando tabelas do schema public...');
    const r = await client.query(`
      SELECT tablename FROM pg_tables WHERE schemaname='public'
      ORDER BY tablename
    `);
    const tabelas = r.rows.map(x => x.tablename);
    console.log(`   ${tabelas.length} tabelas encontradas.`);

    console.log('2. TRUNCATE em todas as tabelas com CASCADE + RESTART IDENTITY...');
    const lista = tabelas.map(t => `"${t}"`).join(', ');
    await client.query(`TRUNCATE TABLE ${lista} RESTART IDENTITY CASCADE`);
    console.log('   OK — todas as tabelas vazias, sequences resetados.');

    console.log('3. Recriando usuario admin...');
    const hash = await bcrypt.hash(ADMIN_PASSWORD, 12);
    const ins = await client.query(`
      INSERT INTO usuarios (email, senha_hash, perfil, nome, ativo, primeiro_acesso, updated_at, created_at)
      VALUES ($1, $2, 'admin', $3, true, false, NOW(), NOW())
      RETURNING id, email, perfil, ativo
    `, [ADMIN_EMAIL, hash, ADMIN_NOME]);
    console.log('   Admin recriado:', ins.rows[0]);

    console.log(`\n✅ Pronto. Login: ${ADMIN_EMAIL}  /  Senha: ${ADMIN_PASSWORD}`);
  } finally {
    client.release();
    pool.end();
  }
})().catch(e => { console.error('ERRO:', e.message); process.exit(1); });
